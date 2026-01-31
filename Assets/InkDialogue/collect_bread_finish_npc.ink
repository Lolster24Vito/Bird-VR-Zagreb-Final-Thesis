=== CollectBreadFinish ===
{ CollectBreadQuestState:
    - "FINISHED": -> finished
    - else: -> default
}

= finished
Thank you!
-> END

= default
Hm? What do you want?
* [Nothing, I guess.]
    -> END
* { CollectBreadQuestState == "CAN_FINISH" } [Here are some coins.]
    ~ FinishQuest(CollectBreadQuestId)
    Oh? These coins are for me? Thank you!
-> END