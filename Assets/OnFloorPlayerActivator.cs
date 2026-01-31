using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class OnFloorPlayerActivator : MonoBehaviour
{
    [SerializeField] GlideStateMachineBodyPoses glideStateMachineBody;
    private void OnCollisionEnter(Collision collision)
    {
        glideStateMachineBody.OnTheCollisionWithFloor();
    }
    private void OnCollisionExit(Collision collision)
    {
        glideStateMachineBody.OnExitCollisionWithFloor();

    }
}
