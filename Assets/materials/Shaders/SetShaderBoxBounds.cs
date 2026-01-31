using System.Collections;
using System.Collections.Generic;
using UnityEngine;


/// <summary>
/// This component MUST be placed on the same GameObject as the MeshRenderer
/// that has the VolumetricCubeClouds shader.
/// 
/// It gets the cube's world-space bounding box and feeds it to the
/// shader every frame.
/// </summary>
[RequireComponent(typeof(MeshRenderer))]
[ExecuteInEditMode] // Allows this to run in the editor
public class SetShaderBoxBounds : MonoBehaviour
{
    private MeshRenderer rend;
    private MaterialPropertyBlock propBlock;

    void OnEnable()
    {
        rend = GetComponent<MeshRenderer>();
        propBlock = new MaterialPropertyBlock();
    }

    /// <summary>
    /// CRITICAL FIX: This must run in Update(), not Start().
    /// If it only runs in Start(), the shader will have the wrong bounds
    /// if the object ever moves, rotates, or scales.
    /// </summary>
    void Update()
    {
        if (rend == null)
        {
            OnEnable(); // Try to re-initialize if lost
            if (rend == null) return;
        }

        // Get the renderer's world-space bounds.
        // This is an Axis-Aligned Bounding Box (AABB).
        var bounds = rend.bounds;

        // Use a MaterialPropertyBlock to set shader properties.
        // This is more efficient than creating new material instances.
        rend.GetPropertyBlock(propBlock);
        propBlock.SetVector("_BoxMin", bounds.min);
        propBlock.SetVector("_BoxMax", bounds.max);
        rend.SetPropertyBlock(propBlock);

        // ---
        // WARNING: This method (renderer.bounds) is simple but has a flaw:
        // If you *rotate* the cube, the world-space AABB will become
        // *larger* than the cube itself. This will cause the clouds to
        // render in the empty space at the corners of the AABB.
        //
        // If this is a problem, the "correct" solution is more complex:
        // 1. Pass the object's local-to-world matrix to the shader.
        // 2. Pass the cube's *local* bounds (e.g., -0.5 to 0.5) to the shader.
        // 3. In the shader, transform the ray into *local space* and
        //    do the RayBoxIntersection against the *local* bounds.
        //
        // For now, this `Update()` solution will work perfectly as long
        // as you don't rotate the cube (or only rotate it 90 degrees
        // on its axes).
        // ---
    }
}