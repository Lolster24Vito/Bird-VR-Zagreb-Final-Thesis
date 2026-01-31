using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CollectBreadQuestStep : QuestStep
{
    private int breadCollected = 0;
    private int breadToComplete = 4;
    //
    private int breadAtStart=1;
    private void OnEnable()
    {
        GameEventsManager.Instance.breadEvents.onBreadCollected += BreadCollected;
        breadAtStart = BreadManager.Instance.currentBreadAmount;
        UpdateState();
    }
    private void OnDisable()
    {
        GameEventsManager.Instance.breadEvents.onBreadCollected -= BreadCollected;

    }
    private void BreadCollected()
    {
        /*
        breadCollected=BreadManager.Instance.currentBreadAmount - breadAtStart;

       
        if (breadCollected >= breadToComplete)
        {
            FinishQuestStep();
        }*/
        
        if (breadCollected < breadToComplete)
        {
            breadCollected++;
            UpdateState();
        }
        if (breadCollected >= breadToComplete)
        {
            FinishQuestStep();
        }
    }
    private void UpdateState()
    {
        string state = breadCollected.ToString();
        string status = "Collected " + breadCollected + " / " + breadToComplete + " coins.";
        ChangeState(state, status);
    }

    protected override void SetQuestStepState(string state)
    {
        int result = 0;
        bool parsable = System.Int32.TryParse(state, out result);
        if (parsable)
        {
            this.breadCollected = result;
            UpdateState(); 
        }
    }
}
