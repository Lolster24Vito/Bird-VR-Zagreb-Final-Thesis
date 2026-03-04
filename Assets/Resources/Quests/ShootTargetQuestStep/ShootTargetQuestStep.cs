using UnityEngine;

[RequireComponent(typeof(Collider))]
public class ShootTargetQuestStep : QuestStep
{
    [Header("Config")]
    [SerializeField] private int targetsToHit = 3;

    private int targetsHit = 0;
    private int bulletLayer;

    private void Awake()
    {
        // Cache the layer index for "PlayerBullet" for better performance
        bulletLayer = LayerMask.NameToLayer("PlayerBullet");
    }

    private void OnEnable()
    {
        UpdateState();
    }

    private void OnCollisionEnter(Collision collision)
    {
        // Check if the object hitting this box is on the PlayerBullet layer
        if (collision.gameObject.layer == bulletLayer)
        {
            TargetHit();
        }
    }

    private void TargetHit()
    {
        if (targetsHit < targetsToHit)
        {
            targetsHit++;
            UpdateState();
        }

        // If we've reached the goal, finish this step
        if (targetsHit >= targetsToHit)
        {
            FinishQuestStep();
        }
    }

    private void UpdateState()
    {
        string state = targetsHit.ToString();
        string status = "Target Practice: Shot " + targetsHit + " / " + targetsToHit + " targets.";

        ChangeState(state, status);
    }

    protected override void SetQuestStepState(string state)
    {
        if (int.TryParse(state, out int result))
        {
            this.targetsHit = result;
            UpdateState();
        }
    }
}