// quest ids (questId + "Id" for variable name)
VAR CollectBreadQuestId = "CollectBreadQuest"
VAR VisitPillarsQuestId = "VisitPillarsQuest"


// quest states (questId + "State" for variable name)
VAR CollectBreadQuestState = "REQUIREMENTS_NOT_MET"
VAR VisitPillarsQuestState = "REQUIREMENTS_NOT_MET"

// external functions
EXTERNAL StartQuest(questId)
EXTERNAL AdvanceQuest(questId)
EXTERNAL FinishQuest(questId)



// ink files
INCLUDE collect_bread_start_npc.ink
INCLUDE collect_bread_finish_npc.ink
INCLUDE visit_pillars_quest.ink