=== collectCoinsStart ===
{ CollectBreadQuestState :
    - "REQUIREMENTS_NOT_MET": -> requirementsNotMet
    - "CAN_START": -> canStart
    - "IN_PROGRESS": -> inProgress
    - "CAN_FINISH": -> canFinish
    - "FINISHED": -> finished
    - else: -> END
}

= requirementsNotMet
// not possible for this quest, but putting something here anyways
Come back once you've leveled up a bit more.
this is a bug but can it print multiple lines
lets see
-> END

= canStart
Will you collect 5 coins and bring them to my friend over there?
* [No]
    Oh, ok then. Come back if you change your mind.
* [Yes]
    ~ StartQuest(CollectBreadQuestId)
    Great!
- ->END

= inProgress
How is collecting those coins going?
-> END

= canFinish
Oh? You collected the coins? Go give them to my friend over there and he'll give you a reward!
-> END

= finished
Thanks for collecting those coins!
-> END