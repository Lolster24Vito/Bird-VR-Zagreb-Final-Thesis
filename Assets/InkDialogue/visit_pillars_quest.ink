// visit pillars quest

=== VisitPillarsQuest ===
{ VisitPillarsQuestState:
- "REQUIREMENTS_NOT_MET": -> requirementsNotMet
- "CAN_START": -> canStart
- "IN_PROGRESS": -> inProgress
- "CAN_FINISH": -> canFinish
- "FINISHED": -> finished
- else: -> END
}
= requirementsNotMet
You look a little lost. Are you looking for a quest? This one requires you to have completed the bread quest first.
-> END
= canStart
I need you to go to the three ancient pillars on the eastern side of the island. Just visit all three of them for me. Will you do this?

*[No]
Okay, I understand. Let me know if you change your mind.

-> END

*[Yes]
~ StartQuest(VisitPillarsQuestId)
Thank you! I'll be waiting for your return.

-> END

= inProgress
Have you made it to the pillars yet? I'll be here waiting.
-> END

= canFinish
You've done it! You made it to all three pillars. Thank you for your help.
~ FinishQuest(VisitPillarsQuestId)
-> END

= finished
Thank you again for all of your help.
-> END