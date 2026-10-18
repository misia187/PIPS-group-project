# Script: variable_key.R
# Purpose: Build the variable key for the Mentalillness dataset: one row per
#          column with its original name, a short name, the disorder it
#          belongs to, and the DSM-5 criterion it counts toward.
#          Uses key_row() from functions.R, so source that script first.
# Date: 2026-10-18

#-------------------------------------------------------------------
# 1. LOAD PACKAGES
# No packages needed: this script only uses base R.
#-------------------------------------------------------------------

#-------------------------------------------------------------------
# 2. BUILD VARIABLE KEY
# Columns of the key:
#   original  = column name in the CSV
#   name      = short name we use in R
#   disorder  = which disorder the column belongs to
#   criterion = which DSM-5 criterion it counts toward
#
# The diagnoses in the data follow these rules exactly:
#   Bipolar       at least 3 of 7 symptoms
#   Depression    at least 5 of 9 symptoms
#   Anxiety       at least 2 of 6 symptoms AND 6-month duration
#   Schizophrenia at least 1 "positive" symptom AND at least 2 items in
#                 total (the 6 symptoms + the 1-month duration item)
#   PTSD          A >= 1, B >= 1, C >= 1, D >= 2, E >= 2,
#                 and F, G and H all present
#-------------------------------------------------------------------

# make_variable_key()
# Builds the full variable key.
# Input:  none
# Output: a data frame with 58 rows (53 symptoms/criteria + 5 diagnoses)
#         and columns original, name, disorder, criterion
make_variable_key <- function() {
  rbind(
    # Bipolar
    key_row("Inflated self-esteem", "bip_inflated_self_esteem", "bipolar", "symptom"),
    key_row("Distractibility", "bip_distractibility", "bipolar", "symptom"),
    key_row("Increase in goal-directed activity", "bip_goal_directed_activity", "bipolar", "symptom"),
    key_row("Excessive involvement in activities with high potential for painful consequences",
            "bip_risky_activities", "bipolar", "symptom"),
    key_row("Racing thoughts", "bip_racing_thoughts", "bipolar", "symptom"),
    key_row("Decreased need for sleep", "bip_decreased_sleep_need", "bipolar", "symptom"),
    key_row("More talkative than usual", "bip_talkative", "bipolar", "symptom"),
    
    # Schizophrenia
    key_row("Disorganized thinking or speech", "scz_disorganized_speech", "schizophrenia", "positive"),
    # Sounds like a PTSD symptom, but it counts toward schizophrenia
    key_row("Intrusive memories or flashbacks", "scz_intrusive_memories", "schizophrenia", "other"),
    key_row("Diminished emotional expression", "scz_diminished_expression", "schizophrenia", "other"),
    key_row("Delusions", "scz_delusions", "schizophrenia", "positive"),
    key_row("Hallucinations", "scz_hallucinations", "schizophrenia", "positive"),
    key_row("Catatonic behavior", "scz_catatonic_behavior", "schizophrenia", "other"),
    key_row("1 month duration", "scz_duration_1_month", "schizophrenia", "duration"),
    
    # Depression
    key_row("Depressed mood", "dep_depressed_mood", "depression", "symptom"),
    key_row("Persistent sadness or low mood", "dep_persistent_sadness", "depression", "symptom"),
    key_row("Loss of interest or pleasure in activities", "dep_loss_of_interest", "depression", "symptom"),
    key_row("Fatigue or loss of energy", "dep_fatigue", "depression", "symptom"),
    key_row("Difficulty concentrating or making decisions", "dep_concentration", "depression", "symptom"),
    key_row("Lack of sleep or oversleeping", "dep_sleep_change", "depression", "symptom"),
    key_row("Psychomotor agitation", "dep_psychomotor_agitation", "depression", "symptom"),
    key_row("Thoughts of suicide", "dep_suicidal_thoughts", "depression", "symptom"),
    key_row("Weight loss or gain", "dep_weight_change", "depression", "symptom"),
    
    # Anxiety
    key_row("Excessive worry or fear", "anx_excessive_worry", "anxiety", "symptom"),
    key_row("Fatigue", "anx_fatigue", "anxiety", "symptom"),
    key_row("Sleep disturbance", "anx_sleep_disturbance", "anxiety", "symptom"),
    key_row("Difficulty concentrating", "anx_concentration", "anxiety", "symptom"),
    key_row("Restlessness", "anx_restlessness", "anxiety", "symptom"),
    key_row("Irritability", "anx_irritability", "anxiety", "symptom"),
    key_row("6 month duration", "anx_duration_6_months", "anxiety", "duration"),
    
    # PTSD (DSM-5 criteria A to H)
    key_row("Experiencing traumatic event", "ptsd_experienced_trauma", "ptsd", "A_exposure"),
    key_row("Witnessing traumatic event", "ptsd_witnessed_trauma", "ptsd", "A_exposure"),
    key_row("Dissociative reaction", "ptsd_dissociative_reaction", "ptsd", "B_intrusion"),
    key_row("Recurrent distressing dreaming affiliated with the traumatic event",
            "ptsd_distressing_dreams", "ptsd", "B_intrusion"),
    key_row("Intense distress or reaction when exposed to cues affiliated with the traumatic event",
            "ptsd_distress_at_cues", "ptsd", "B_intrusion"),
    key_row("Intrusive memories or flashback", "ptsd_intrusive_memories", "ptsd", "B_intrusion"),
    key_row("Avoidance of reminders of traumatic event", "ptsd_avoid_reminders", "ptsd", "C_avoidance"),
    key_row("Avoidance of external reminders of traumatic event",
            "ptsd_avoid_external_reminders", "ptsd", "C_avoidance"),
    key_row("Persistent and exaggerated negative belief about oneself or the world",
            "ptsd_negative_beliefs", "ptsd", "D_cognition_mood"),
    key_row("Persistent loss of memory about the cause or consequences of the traumatic event",
            "ptsd_memory_loss", "ptsd", "D_cognition_mood"),
    key_row("Persistent negative emotional state", "ptsd_negative_emotional_state", "ptsd", "D_cognition_mood"),
    key_row("Diminished interest", "ptsd_diminished_interest", "ptsd", "D_cognition_mood"),
    key_row("Feeling of detachment", "ptsd_detachment", "ptsd", "D_cognition_mood"),
    key_row("Persistent inability to experience positive emotions",
            "ptsd_no_positive_emotions", "ptsd", "D_cognition_mood"),
    key_row("Angry outburst", "ptsd_angry_outbursts", "ptsd", "E_arousal"),
    key_row("Recklessness", "ptsd_recklessness", "ptsd", "E_arousal"),
    key_row("Hypervigilance", "ptsd_hypervigilance", "ptsd", "E_arousal"),
    key_row("Exaggerated startle response", "ptsd_startle_response", "ptsd", "E_arousal"),
    key_row("Concentration issues", "ptsd_concentration", "ptsd", "E_arousal"),
    key_row("Sleep disturbance (PTSD)", "ptsd_sleep_disturbance", "ptsd", "E_arousal"),
    key_row("More than one month of disturbance", "ptsd_duration_1_month", "ptsd", "F_duration"),
    key_row("The disturbance causes clinically significant distress",
            "ptsd_clinical_distress", "ptsd", "G_distress"),
    key_row("The disturbance is not substance induced",
            "ptsd_not_substance_induced", "ptsd", "H_not_substance"),
    
    # Diagnoses
    key_row("Bipolar disorder", "dx_bipolar", "bipolar", "diagnosis"),
    key_row("Schizophrenia", "dx_schizophrenia", "schizophrenia", "diagnosis"),
    key_row("Depression", "dx_depression", "depression", "diagnosis"),
    key_row("Anxiety disorder", "dx_anxiety", "anxiety", "diagnosis"),
    key_row("PTSD", "dx_ptsd", "ptsd", "diagnosis")
  )
}

