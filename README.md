# CareLoop Clinics — No-Show Guard

https://github.com/spandan-bit/CareLoop-No-Show-Guard

## Summary (One Finding Per Part)

1. **Part 1 (Data Foundations):** Cleaned 1,020 raw bookings into 990 valid appointments; 22.0% overall no-show rate; outliers capped (26 distance, 3 fee).
2. **Part 2 (SQL Analysis):** No-shows cluster at Gomti Nagar (33.3%, 90 appts) and rise sharply with lead time — 60.5% no-show rate for 31+ day lead.
3. **Part 3 (ML Model):** Logistic Regression selected (CV ROC-AUC = 0.774); threshold 0.35 gives 57% recall on test set, flagging 49 risky bookings.
4. **Part 4 (GenAI Notes):** Of 10 call-centre notes analysed, 9 valid; top reasons from notes: forgot/no reminder, distance, work conflicts.

## Recommendation

CareLoop should prioritise **automated reminders for bookings with lead time >14 days** (29.9% of appointments, 30.0% no-show rate in 15-30 day band, 60.5% in 31+ band) and **targeted follow-up calls for patients with prior no-shows** (lead_days and prior_no_shows both have strong positive coefficients in the model). The model flags 49 high-risk appointments per 198 test cases at threshold 0.35, with 57% recall — meaning over half of actual no-shows are caught. GenAI analysis confirms that 2 of 10 notes cite forgotten appointments, and 5 of 10 analysed notes had no reminder sent. Deploying reminders for all bookings >7 days out and phoning the top-49 risk-scored patients each evening would address the largest avoidable causes.

## Model Chosen

**Logistic Regression** (5-fold CV ROC-AUC = 0.774) — highest among all candidates (Depth-3 Tree: 0.678, Random Forest: 0.742, Tuned RF: 0.774). Threshold **0.35** chosen via out-of-fold F1 optimisation, yielding test recall=0.57, precision=0.57, flagging 49 appointments.

## Limitations

1. The 10 analysed notes are an illustration and cannot show real clinic-wide reasons.
2. Cleaning statistics (medians, quartiles, outlier fences) were computed on all 990 rows before the train/test split, giving test rows indirect influence.
3. The same patient can appear in both training and test sets (random split), and the split is random rather than past-to-future.

---
*All code in this repository uses only free tools: Python (pandas, scikit-learn), SQL (MySQL/SQLite), and Gemini API (free tier).*
