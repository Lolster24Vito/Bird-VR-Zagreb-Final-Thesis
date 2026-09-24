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
* [Nothing]
    -> END
* { CollectBreadQuestState == "CAN_FINISH" } [Give bread]
    ~ FinishQuest(CollectBreadQuestId)
    Oh? These breads are for me? Thank you!
-> END