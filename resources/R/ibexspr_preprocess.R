
library(tidyverse)
library(dplyr)
library(lme4)
library(lmerTest)
library(readr)
library(ordinal)

select <- dplyr::select


spr1 <- read_csv("C:/Users/znhua/OneDrive/Documents/gh/texfiles/null/nullspr/pomelo_spr1_39res20210719.csv", 
    col_names = c("time", "participant", 
                  "tasktype", # self-paced reading, acceptability judgment, ...
                  "ibex.item.number", "ibex.type", # not sure what these columns are about
                  "condition", # condition (Latin Square)
                  "s.no", # sentence number (Latin Square)
                  "linpos.q", # linear position of a region in SPR, or text of a comprehension question
                  "lex.resp", # words in a SPR region, or participant response to a comprehension question
                  "rt.ans", # RT for SPR. For questions, "1" if the response is correct, "0" if the response is wrong, "NULL" if there is no correct or wrong answer.
                  "rt.q", # RT for question. For other paradigms, whether this word is on a newline (??? according to Ibex)
                  "full.s" # Full sentence in SPR
                  )) %>%
  filter(tasktype != 'Form') %>% # Exclude responses collected via forms -- participant demographic information, consent, ...
  filter(!startsWith(time, "#")) # Exclude all rows that start with "#  ..." (these are comments)

pilot.participants <- head(unique(spr1$participant), 12)

spr2 <- read_csv("C:/Users/znhua/OneDrive/Documents/gh/texfiles/null/nullspr/pomelo_spr1_30res20210724.csv", 
           col_names = c("time", "participant", 
                         "tasktype", # self-paced reading, acceptability judgment, ...
                         "ibex.item.number", "ibex.type", # not sure what these columns are about
                         "condition", # condition (Latin Square)
                         "s.no", # sentence number (Latin Square)
                         "linpos.q", # linear position of a region in SPR, or text of a comprehension question
                         "lex.resp", # words in a SPR region, or participant response to a comprehension question
                         "rt.ans", # RT for SPR. For questions, "1" if the response is correct, "0" if the response is wrong, "NULL" if there is no correct or wrong answer.
                         "rt.q", # RT for question. For other paradigms, whether this word is on a newline (??? according to Ibex)
                         "full.s" # Full sentence in SPR
           )) %>%
  #filter(participant != 'edebf94f5215a63f02c883b0a2f339e8') # accidentally collected
  filter(tasktype != 'Form') %>% # Exclude responses collected via forms -- participant demographic information, consent, ...
  filter(!startsWith(time, "#")) # Exclude all rows that start with "#  ..." (these are comments)
  

spr <- rbind(spr1 %>% filter(!participant %in% pilot.participants), spr2)

# Note that this will generate a series of "parsing failures" -- a mismatch of number of columns expected vs. number of columns in the file. 
# But R should still read the file correctly.
# View(spr)

spr$log.rt <- ifelse(as.integer(spr$rt.ans) & spr$rt.ans > 0, log10(spr$rt.ans), NA)

# Number of participants
length(unique(spr$participant))

# Identify regions of interest
spr$connective <- ifelse(spr$lex.resp == '则' | spr$lex.resp == '也', "1-connective","")
spr$connective.type <- ifelse(substr(spr$condition,10,12) == 'ze', "While (ze)",
                              ifelse(substr(spr$condition,10,12) == 'ye', "Also (ye)", "else"))

spr$pred.type <- ifelse(substr(spr$condition,6,8) == 'obl', "Requires NP cont.",
                              ifelse(substr(spr$condition,6,8) == 'opt', "Allows null object", "else"))

spr$labeled.region <- ifelse(spr$connective == '1-connective', '1-connective',
                             ifelse(lead(spr$connective, 1) == '1-connective', '0-sbj',
                             ifelse(lag(spr$connective, 1) == '1-connective', '2-adverb',
                             ifelse(lag(spr$connective, 2) == '1-connective', '3-pred',
                             ifelse(lag(spr$connective, 3) == '1-connective', '4-det',
                             ifelse(lag(spr$connective, 4) == '1-connective', '5-noun',
                                    ifelse(lag(spr$connective, 5) == '1-connective', '6-but',
                                           ifelse(lag(spr$connective, 6) == '1-connective', '7-nomatter', "else"
                                           ))
                                    )
                                    )
                                    )
                                    )
                             )
)



# Extract only comprehension questions
comp.q <- spr %>% filter(tasktype == "Question") %>% 
  select(c(participant, condition, s.no, rt.ans, connective.type, pred.type)) %>%
  rename(correct = rt.ans) # change "rt.ans" to something clearer


# Merge responses to comprehension question with RTs.
# So we know, for a given region and RT, whether the participant eventually answered the comprehension question correctly or not.
spr <- merge(spr %>% filter(tasktype != 'Question'),
             comp.q, by = c("participant", "condition", "s.no"), 
             all = T # keep a row in SPR even if there might not be a comprehension question
             ) %>% 
  arrange(participant, condition, s.no, as.integer(linpos.q))

#####


# Participant comprehension accuracy for all items (filler and target items)
comp.q %>% group_by(participant) %>% 
  summarise(n.correct = sum(correct),
            n.total = n(),
            pc.correct = round(n.correct/n.total * 100, 1)) %>%
  arrange(pc.correct) # sort percentage correct by ascending order

# Comprehension accuracy by condition
comp.q %>% filter(connective.type != "else") %>% 
  group_by(condition) %>% 
  summarise(n.correct = sum(correct),
            n.total = n(),
            pc.correct = round(n.correct/n.total * 100, 1)) %>%
  arrange(pc.correct) # sort percentage correct by ascending order

# Comprehension accuracy analysis
comp.q.2x2 <- comp.q %>% filter(connective.type != "else") %>% 
  group_by(participant, connective.type, pred.type) %>% 
  summarise(n.correct = sum(correct),
            n.total = n(),
            pc.correct = round(n.correct/n.total * 100, 1)) %>%
  arrange(pc.correct) # sort percentage correct by ascending order

summary(lm(pc.correct ~ connective.type * pred.type, data = comp.q.2x2))

# (1+connective.type * pred.type|participant) -- not enough observations
# (1+connective.type + pred.type|participant) -- does not converge
comp.q.lmer <- lmer(pc.correct ~ connective.type * pred.type + (1|participant), 
             data = comp.q.2x2)
summary(comp.q.lmer)
#####

data = spr %>%
  filter(substr(condition, 1,3) == "exp" & correct == 1 & rt.ans <= 2000 & rt.ans >= 100 
         # & !participant %in% c("f195e9241df7fa9efdb2fffe893f8a03", "c6a29432389b48a5f33d2c206d08cc5a")
  ) %>%
  group_by( condition, labeled.region, lex.resp) %>% 
  summarise(
    mean.rt = mean(rt.ans), se.rt = sd(rt.ans)/ sqrt(n()), n = n()
  )

ggplot(data = spr %>%
         filter(substr(condition, 1,3) == "exp" & correct == 1 & rt.ans <= 3000 & rt.ans >= 100 &
                  labeled.region != "else"
                # & !participant %in% c("f195e9241df7fa9efdb2fffe893f8a03", "c6a29432389b48a5f33d2c206d08cc5a")
                ) %>%
         group_by( condition, labeled.region) %>% 
         summarise(
           mean.rt = mean(rt.ans), se.rt = sd(rt.ans)/ sqrt(n()), n = n()
         ), 
       aes(x = labeled.region, y = mean.rt, group = condition)) + 
  geom_line(aes(color = condition)) +
  geom_errorbar(aes(ymin = mean.rt-se.rt, ymax = mean.rt+se.rt), width=.1, position=position_dodge(0.1))
# + ylim(0, 1250)


summary(lm(log10(rt.ans) ~ pred.type * connective.type, data = spr %>%
             filter(substr(condition, 1,3) == "exp" & labeled.region == "5-noun" & correct == 1 & rt.ans <= 3000 & rt.ans >= 100 
                    # & !participant %in% c("f195e9241df7fa9efdb2fffe893f8a03", "c6a29432389b48a5f33d2c206d08cc5a")
             )
))


ajt <- read_csv("C:/Users/znhua/OneDrive/Documents/gh/texfiles/null/nullspr/pomeloajt/pomelo_ajt2.csv", 
                 col_names = c("time", "participant", 
                               "tasktype", # self-paced reading, acceptability judgment, ...
                               "ibex.item.number", "ibex.type", # not sure what these columns are about
                               "condition", # condition (Latin Square)
                               "s.no", # sentence number (Latin Square)
                               "sentence", # linear position of a region in SPR, or text of a comprehension question
                               "rating", # words in a SPR region, or participant response to a comprehension question
                               "null", # RT for SPR. For questions, "1" if the response is correct, "0" if the response is wrong, "NULL" if there is no correct or wrong answer.
                               "rt" # RT for question. For other paradigms, whether this word is on a newline (??? according to Ibex)
                 )) %>%
  filter(tasktype != 'Form') %>% # Exclude responses collected via forms -- participant demographic information, consent, ...
  filter(!startsWith(time, "#")) # Exclude all rows that start with "#  ..." (these are comments)

ajt$sentence.use <- lag(ajt$sentence, 1)
ajt <- ajt %>% filter(sentence == 'NULL')

# Number of participants
nrow(ajt)/ 84
# RT filter


ajt$pred.type <- ifelse(substr(ajt$condition, 6,8)== 'obl', 'Predicate requiring overt NP',
                        ifelse(substr(ajt$condition, 6,8)== 'opt', 'Predicate allowing null NP', 'else'))
ajt$connective <- ifelse(substr(ajt$condition, 10,11)== 'ye', "Ye 'also'",
                        ifelse(substr(ajt$condition, 10,11)== 'ze', "Ze 'while'", 'else'))
ajt$rating.factor <- as.factor(ajt$rating)

ajt.conds <- ajt %>% filter(startsWith(condition, "exp") & rt >= 2000 )

summary(lm(rating ~ pred.type * connective,
           data = ajt.conds ) )
# takes a long time to converge; perfect correlations between pred.type and connective at an item level
# Random effects:
#   Groups Name                                                       Variance Std.Dev. Corr                 
# s.no   (Intercept)                                                 5.17621 2.2751                        
# pred.typePredicate requiring overt NP                       3.68914 1.9207   -0.649               
# connectiveZe 'while'                                       12.04711 3.4709   -0.753  0.973        
# pred.typePredicate requiring overt NP:connectiveZe 'while'  3.86410 1.9657    0.632 -0.992 -0.983 
# time   (Intercept)                                                 0.01811 0.1346                        
# pred.typePredicate requiring overt NP                       3.00034 1.7321   -1.000               
# connectiveZe 'while'                                        0.13186 0.3631   -1.000  1.000        
# pred.typePredicate requiring overt NP:connectiveZe 'while'  1.87292 1.3685    1.000 -1.000 -1.000 
clmm.model1 <- clmm(rating.factor ~ pred.type*connective + (1+pred.type*connective|time) + (1+pred.type*connective|s.no),
                    data = ajt.conds)
summary(clmm.model1)

# since the full model has high correlations, let's try a slightly simpler model
# Random effects:
#   Groups Name                                                       Variance Std.Dev. Corr                 
# s.no   (Intercept)                                                 4.99998 2.2361                        
# pred.typePredicate requiring overt NP                       3.47814 1.8650   -0.654               
# connectiveZe 'while'                                       11.81195 3.4369   -0.755  0.973        
# pred.typePredicate requiring overt NP:connectiveZe 'while'  3.53279 1.8796    0.639 -0.990 -0.985 
# time   (Intercept)                                                 0.06529 0.2555                        
# pred.typePredicate requiring overt NP                       0.86770 0.9315    1.000               
# connectiveZe 'while'                                        0.09502 0.3082   -1.000 -1.000        
# Number of groups:  time 28,  s.no 28 

clmm.model1a <- clmm(rating.factor ~ pred.type*connective + (1+pred.type*connective|time) + (1+pred.type+connective|s.no),
                    data = ajt.conds)
summary(clmm.model1a)


clmm.model2 <- clmm(rating.factor ~ pred.type*connective + (1+pred.type*connective|time) + (1|s.no),
                    data = ajt.conds)
summary(clmm.model2)

clmm.model3 <- clmm(rating.factor ~ pred.type*connective + (1|time) + (1|s.no),
                    data = ajt.conds)
summary(conditionLmer.1)
