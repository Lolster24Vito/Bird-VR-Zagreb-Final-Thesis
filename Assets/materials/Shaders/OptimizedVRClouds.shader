Shader "Custom/OptimizedVRClouds" {
    Properties{
        _Steps("Steps", Int) = 16
        _StepSize("Step Size", Float) = 50
        _Density("Density", Float) = 0.3
        _NoiseScale("Noise Scale", Float) = 0.008
        _Threshold("Threshold", Float) = 0.4
        _BoxMin("Box Min", Vector) = (-1000,1000,-1000,0)
        _BoxMax("Box Max", Vector) = (1000,2000,1000,0)
        _PhaseG("Scattering g", Range(-1,1)) = 0.2
    }
        SubShader{
            Tags { "Queue" = "Transparent" "RenderType" = "Transparent" }
            LOD 100
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off

            Pass {
                Cull Front
                HLSLPROGRAM
                #pragma vertex Vert
                #pragma fragment Frag
                #pragma target 3.5
                #pragma multi_compile_instancing
                #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN

                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

                #define PI 3.14159265359

                struct Attributes {
                    float4 positionOS : POSITION;
                    UNITY_VERTEX_INPUT_INSTANCE_ID
                };

                struct Varyings {
                    float4 positionCS : SV_POSITION;
                    float3 positionWS : TEXCOORD0;
                    float3 viewDir : TEXCOORD1;
                    UNITY_VERTEX_OUTPUT_STEREO
                };

                float _Steps;
                float _StepSize;
                float _Density;
                float _NoiseScale;
                float _Threshold;
                float3 _BoxMin;
                float3 _BoxMax;
                float _PhaseG;

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

                float henyey_greenstein(float cosTheta, float g) {
                    float g2 = g * g;
                    return (1 - g2) / (4 * PI * pow(1 + g2 - 2 * g * cosTheta, 1.5));
                }

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

                Varyings Vert(Attributes input) {
                    Varyings output;
                    UNITY_SETUP_INSTANCE_ID(input);
                    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                    // Transform to world space
                    output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
                    output.positionCS = TransformWorldToHClip(output.positionWS);

                    // Calculate view direction for VR - this will be different for each eye
                    output.viewDir = GetWorldSpaceNormalizeViewDir(output.positionWS);

                    return output;
                }

                half4 Frag(Varyings input) : SV_Target {
                    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                // Use the correct camera position for each eye in VR
                // In URP, _WorldSpaceCameraPos is already stereo-correct when stereo rendering is active
                float3 camPos = _WorldSpaceCameraPos;
                float3 viewDir = normalize(input.viewDir);

                float2 t = RayBoxIntersection(_BoxMin, _BoxMax, camPos, viewDir);
                float tmin = max(t.x, 0.0);
                float tmax = t.y;

                if (tmin >= tmax || tmax <= 0) {
                    return half4(0,0,0,0);
                }

                float length = tmax - tmin;
                float stepSize = min(length / _Steps, _StepSize);
                int num_steps = min((int)ceil(length / stepSize), (int)_Steps);

                half3 color = 0;
                float alpha = 0;
                float3 pos = camPos + viewDir * tmin;

                Light mainLight = GetMainLight();

                for (int s = 0; s < num_steps; s++) {
                    pos += viewDir * stepSize;
                    float raw = fbm(pos * _NoiseScale);
                    float d = max(0, raw - _Threshold) * _Density;
                    float heightFrac = saturate((pos.y - _BoxMin.y) / (_BoxMax.y - _BoxMin.y));
                    d *= lerp(0.2, 1.0, heightFrac);

                    if (d > 0) {
                        float cosTheta = dot(-viewDir, mainLight.direction);
                        float phase = henyey_greenstein(cosTheta, _PhaseG);
                        float3 lit = mainLight.color * phase * d * stepSize;
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