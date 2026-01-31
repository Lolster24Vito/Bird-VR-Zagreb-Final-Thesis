Shader "Custom/VolumetricCubeClouds" {
    Properties{
        _Steps("Steps (Int)", Int) = 16
        _StepSize("Step Size (Float)", Float) = 50
        _Density("Density", Float) = 0.3
        _NoiseScale("Noise Scale", Float) = 0.008
        _Threshold("Threshold", Float) = 0.4
        _PhaseG("Scattering g", Range(-1,1)) = 0.2
        _NoiseOffset("Noise Offset", Vector) = (0,0,0,0)
        [HideInInspector] _BoxMin("Box Min", Vector) = (-1000,1000,-1000,0)
        [HideInInspector] _BoxMax("Box Max", Vector) = (1000,2000,1000,0)
    }

        SubShader{
            Tags {
                "Queue" = "Transparent"
                "RenderType" = "Transparent"
                "RenderPipeline" = "UniversalPipeline"
            }
            LOD 100

            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            Cull Front

            Pass {
                HLSLPROGRAM
                #pragma vertex Vert
                #pragma fragment Frag
                #pragma target 3.0

                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

                #define PI 3.14159265359

                // Uniform variables
                int _Steps;
                float _StepSize;
                float _Density;
                float _NoiseScale;
                float _Threshold;
                float3 _BoxMin;
                float3 _BoxMax;
                float _PhaseG;
                float3 _NoiseOffset;

                // Vertex input/output structures
                struct Attributes {
                    float4 positionOS : POSITION;
                };

                struct Varyings {
                    float4 positionCS : SV_POSITION;
                    float3 positionWS : TEXCOORD0;
                    float3 rayDir : TEXCOORD1;
                };

                // Noise functions
                float hash(float3 p) {
                    p = frac(p * 0.3183099 + 0.1);
                    p *= 17.0;
                    return frac(p.x * p.y * p.z * (p.x + p.y + p.z));
                }

                float noise(float3 x) {
                    float3 i = floor(x);
                    float3 f = frac(x);
                    f = f * f * (3.0 - 2.0 * f);
                    return lerp(lerp(lerp(hash(i + float3(0,0,0)), hash(i + float3(1,0,0)), f.x),
                                    lerp(hash(i + float3(0,1,0)), hash(i + float3(1,1,0)), f.x), f.y),
                                lerp(lerp(hash(i + float3(0,0,1)), hash(i + float3(1,0,1)), f.x),
                                    lerp(hash(i + float3(0,1,1)), hash(i + float3(1,1,1)), f.x), f.y), f.z);
                }

                float fbm(float3 x) {
                    float v = 0.0;
                    float a = 0.5;
                    float3 shift = float3(100,100,100);
                    for (int i = 0; i < 4; ++i) {
                        v += a * noise(x);
                        x = x * 2.0 + shift;
                        a *= 0.5;
                    }
                    return v;
                }

                // Scattering function
                float henyey_greenstein(float cosTheta, float g) {
                    float g2 = g * g;
                    return (1 - g2) / (4 * PI * pow(1 + g2 - 2 * g * cosTheta, 1.5));
                }

                // Ray-box intersection
                float2 RayBoxIntersection(float3 boxMin, float3 boxMax, float3 rayOrigin, float3 rayDir) {
                    float3 invDir = 1.0 / rayDir;
                    float3 t1 = (boxMin - rayOrigin) * invDir;
                    float3 t2 = (boxMax - rayOrigin) * invDir;
                    float3 tMin = min(t1, t2);
                    float3 tMax = max(t1, t2);
                    float tNear = max(max(tMin.x, tMin.y), tMin.z);
                    float tFar = min(min(tMax.x, tMax.y), tMax.z);
                    if (tNear > tFar || tFar < 0) return float2(-1, -1);
                    return float2(tNear, tFar);
                }

                // Vertex shader
                Varyings Vert(Attributes input) {
                    Varyings output;

                    // Transform to world space
                    output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
                    output.positionCS = TransformWorldToHClip(output.positionWS);

                    // Calculate view direction for ray marching
                    float3 viewDir = GetWorldSpaceNormalizeViewDir(output.positionWS);
                    output.rayDir = -viewDir;

                    return output;
                }

                // Fragment shader
                half4 Frag(Varyings input) : SV_Target {
                    // Use standard URP camera position
                    float3 camPos = _WorldSpaceCameraPos;
                    float3 viewDir = normalize(input.rayDir);

                    float2 t = RayBoxIntersection(_BoxMin, _BoxMax, camPos, viewDir);
                    float tmin = max(t.x, 0.0);
                    float tmax = t.y;

                    if (tmin >= tmax || tmax <= 0) {
                        return half4(0,0,0,0);
                    }

                    float length = tmax - tmin;
                    float step = min(length / _Steps, _StepSize);
                    int num_steps = min((int)ceil(length / step), (int)_Steps);

                    half3 color = 0;
                    float alpha = 0;
                    float3 pos = camPos + viewDir * tmin;

                    Light mainLight = GetMainLight();

                    for (int s = 0; s < num_steps; s++) {
                        pos += viewDir * step;
                        float3 samplePos = pos * _NoiseScale + _NoiseOffset;
                        float raw = fbm(samplePos);
                        float d = max(0, raw - _Threshold) * _Density;
                        float heightFrac = saturate((pos.y - _BoxMin.y) / (_BoxMax.y - _BoxMin.y));
                        d *= lerp(0.2, 1.0, heightFrac);

                        if (d > 0) {
                            float cosTheta = dot(-viewDir, mainLight.direction);
                            float phase = henyey_greenstein(cosTheta, _PhaseG);
                            float3 lit = mainLight.color * phase * d * step;
                            color += lit * (1 - alpha);
                            alpha += d * (1 - alpha);
                        }
                    }

                    return half4(color, alpha);
                }
                ENDHLSL
            }
    }
}