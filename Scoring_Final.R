if (!require('readxl')) install.packages('readxl')
if (!require('caret')) install.packages('caret')
if (!require('ROCR')) install.packages('ROCR')
if (!require('lift')) install.packages('lift')
if (!require('ggplot2')) install.packages('ggplot2')
if (!require('e1071')) install.packages('e1071')
if (!require('ROSE')) install.packages('ROSE')
if (!require('DMwR')) install.packages('DMwR', dependencies = TRUE)

library(unbalanced)  
library(Hmisc)
library(readxl)
library(dplyr)
library(ggplot2)
library(corrplot)
library(xlsx)
library(psych)
library("cluster")
library("fpc")
library(ROSE)
library(DMwR)

#leer archivos

score<-read_excel("C:/Users/ASUS/Documents/score-train.xlsx")

score.tr<-read_excel("C:/Users/ASUS/Documents/score-test.xlsx")

str(score)


#convertir en factor las variables que lo son

score$Empleado <-factor(score$Empleado)

score$puntaje <-(score$Impulsividad + score$Confianza)
#convertir variables en dummies

#score_dummies<-dummyVars("~.",data=score)
#score_dummies_fin<-as.data.frame(predict(score_dummies,newdata=score))
#eliminar una variable Empleado para evitar multicolinealidad

score.train<-within(score,rm(id,Empleado))

score_fin$Incumplimiento <- factor(score_fin$Incumplimiento)



str(score_fin)

#exploracion de varibles independientes (antes de separar en entrenamiento y validacion)
matrizcor<-cor(score_fin[,2:8])
write.xlsx(matrizcor, "C:/Users/ASUS/Documents/corre.xlsx")

corrplot(matrizcor, method = "number",number.cex = 0.7)

descriptivos <- (describe(score_fin))
presta<-function (x){
  case_when(
    x == 0 ~ 1,
    x =! 0 ~ 0
  )
}
score_fin$Sin_Presta<-factor(presta(score_fin$Valor_prestamo))

par(mfrow=c(3,2))
for (variable in vector) {
  
}

hist1

hist2

hist3
hist4
hist5
hist6

hist1 <- ggplot(score.train, aes(Tiempo_empleo)) + geom_density(fill="#6DC36D", colour="white") + labs(x = "Tiempo_empleo", y="Acumulado")
hist2 <- ggplot(score.train, aes(Saldo_cuenta)) + geom_density(fill="#6DC36D", colour="green") + labs(x = "Saldo_cuenta", y="Acumulado")
hist3 <- ggplot(score.train, aes(Valor_prestamo)) + geom_density(fill="#6DC36D", colour="white") + labs(x = "Valor_prestamo", y="Acumulado")
hist4 <- ggplot(score.train, aes(Autocontrol)) + geom_density(fill="#6DC36D", colour="white") + labs(x = "Autocontrol", y="Acumulado")
hist5 <- ggplot(score.train, aes(Impulsividad)) + geom_density(fill="#6DC36D", colour="white") + labs(x = "Impulsividad", y="Acumulado")
hist6 <- ggplot(score.train, aes(Confianza)) + geom_density(fill="#6DC36D", colour="white") + labs(x = "Confianza", y="Acumulado")

summary(score_fin)
hist(score_fin)
#proporciones para ver si los datos estan imbalanceados
prop.table(table(score_fin$Incumplimiento))


#particion del dataset, en principio, no vamos a pensar en modelos que requieran hiperparametos, por lo que solo requiero entrenamiento y validacion
#set.seed(4321)
set.seed(1)

sample <- sample(2, nrow(score_fin), replace = TRUE, prob = c(0.60,0.40))

score.train <- score_fin[sample ==1,]
write.csv(score.train, "C:/Users/ASUS/Documents/train60.csv")

score.test <- score_fin[sample ==2,]


boxplot(score.train$Saldo_cuenta)

plot(score.train$Valor_prestamo,score.train$Saldo_cuenta)

# 1. correr modelo regresion logistica
###############################
modelo.logit<-glm(Incumplimiento~.,family=binomial,score.train)

#trace=0 impide ver todos los detalles de la optimización stepwise
steplogit<-step(modelo.logit, direction="both", trace=0)

summary(steplogit)


#evaluacion de coeficientes

coeficientes<-steplogit$coefficients
odd_change<-exp(coeficientes)
odd_change
balance<-table(score.train$Incumplimiento)
prop.table(balance)
oddbase<-prop.table(balance)[2]/prop.table(balance)[1]
oddbase
oddfin<-oddbase*odd_change
prob1step<-oddfin/(1+oddfin)
prob1step

c<-cbind(coeficientes,odd_change,oddbase,oddfin,prob1step)
c
write.xlsx(c, "C:/Users/ASUS/Documents/odd1.xlsx")

#crea el pronostico base de entrenamiento

prontrain<-ifelse(steplogit$fitted.values > 0.65,1,0)
#tabla de confusión y estad�?sticas, base de entrenamiento
library(caret)
score.train$Incumplimiento<-as.factor(score.train$Incumplimiento)
conftrain<-confusionMatrix(as.factor(prontrain),score.train$Incumplimiento, positive = "1")
conftrain$table
conftrain$byClass
conftrain$overall

a<-as.data.frame(conftrain$byClass)

#crea el pronóstico en validación
probtest<-predict(steplogit,newdata = score.test,type='response')
prontest<-ifelse(probtest > 0.65,1,0)
score.test$Incumplimiento<-as.factor(score.test$Incumplimiento)
conftest<-confusionMatrix(as.factor(prontest),score.test$Incumplimiento, positive = "1")
conftest$table
conftest$byClass
conftest$overall #esto trae el accuracy, que representa los casos en los que predijo bien ya sea ceros o unos del total del dataset de prueba

a<-cbind(a,conftest$byClass)

###############################
# 2. balancear los datos 
# 2.1 Oversampling

###############################
library(ROSE)

table(score.train$Incumplimiento)
prop.table(table(score.train$Incumplimiento))
over <- ovun.sample(Incumplimiento~.,data = score.train, method = "over", N = 61870)$data
table(over$Incumplimiento)
summary(over)
summary(score_fin)

# 2.1.1. correr modelo con oversampling
modelo.logit_over<-glm(Incumplimiento~.,family=binomial,over)
steplogit_over<-step(modelo.logit_over, direction="both", trace=0)
summary(steplogit_over)

#evaluacion de coeficientes

coeficientes<-steplogit_over$coefficients
odd_change<-exp(coeficientes)
odd_change
balance<-table(over$Incumplimiento)
prop.table(balance)
oddbase<-prop.table(balance)[2]/prop.table(balance)[1]
oddbase
oddfin<-oddbase*odd_change
prob1step<-oddfin/(1+oddfin)
prob1step

c<-cbind(coeficientes,odd_change,oddbase,oddfin,prob1step)
c
write.xlsx(c, "C:/Users/ASUS/Documents/odd2.xlsx")




#crea el pronostico base de entrenamiento


prontrain_over<-ifelse(steplogit_over$fitted.values > 0.65,1,0)
over$Incumplimiento<-as.factor(over$Incumplimiento)
conftrain_over<-confusionMatrix(as.factor(prontrain_over),over$Incumplimiento, positive = "1")
conftrain_over$table
conftrain_over$byClass
conftrain_over$overall

a<-cbind(a,conftrain_over$byClass)

#crea el pronóstico en validación
probtest_over<-predict(steplogit_over,newdata = score.test,type='response')
prontest_over<-ifelse(probtest_over > 0.65,1,0)
conftest_over<-confusionMatrix(as.factor(prontest_over),score.test$Incumplimiento, positive = "1")
conftest_over$table
conftest_over$byClass
conftest_over$overall

a<-cbind(a,conftest_over$byClass)

###############################

# 2.2 Undersampling
###############################
table(score.train$Incumplimiento)

under <- ovun.sample(Incumplimiento~.,data = score.train, method = "under", N = 10072)$data
table(under$Incumplimiento)
summary(under)


# 2.2.1. correr modelo con undersampling
modelo.logit_under<-glm(Incumplimiento~.,family=binomial,under)
steplogit_under<-step(modelo.logit_under, direction="both", trace=0)
summary(steplogit_under)


#evaluacion de coeficientes

coeficientes<-steplogit_under$coefficients
odd_change<-exp(coeficientes)
odd_change
balance<-table(under$Incumplimiento)
prop.table(balance)
oddbase<-prop.table(balance)[2]/prop.table(balance)[1]
oddbase
oddfin<-oddbase*odd_change
prob1step<-oddfin/(1+oddfin)
prob1step

c<-cbind(coeficientes,odd_change,oddbase,oddfin,prob1step)
c
write.xlsx(c, "C:/Users/ASUS/Documents/odd3.xlsx")


#crea el pronostico base de entrenamiento
prontrain_under<-ifelse(steplogit_under$fitted.values > 0.65,1,0)
under$Incumplimiento<-as.factor(under$Incumplimiento)
conftrain_under<-confusionMatrix(as.factor(prontrain_under),under$Incumplimiento, positive = "1")
conftrain_under$table
conftrain_under$byClass
conftrain_under$overall

a<-cbind(a,conftrain_under$byClass)
#crea el pronóstico en validación
probtest_under<-predict(steplogit_under,newdata = score.test,type='response')
prontest_under<-ifelse(probtest_under > 0.65,1,0)
conftest_under<-confusionMatrix(as.factor(prontest_under),score.test$Incumplimiento, positive = "1")
conftest_under$table
conftest_under$byClass
conftest_under$overall

a<-cbind(a,conftest_under$byClass)

###############################

#2.3 hacer sampling en ambas direcciones (both)


###############################
both <- ovun.sample(Incumplimiento~., data = score.train, method = "both", p = 0.5, seed = 1, N = 35971)$data
table(both$Incumplimiento)

# 2.3.1. correr modelo con both

modelo.logit_both<-glm(Incumplimiento~.,family=binomial,both)
steplogit_both<-step(modelo.logit_both, direction="both", trace=0)
summary(steplogit_both)

#evaluacion de coeficientes

coeficientes<-steplogit_both$coefficients
odd_change<-exp(coeficientes)
odd_change
balance<-table(both$Incumplimiento)
prop.table(balance)
oddbase<-prop.table(balance)[2]/prop.table(balance)[1]
oddbase
oddfin<-oddbase*odd_change
prob1step<-oddfin/(1+oddfin)
prob1step
c<-cbind(coeficientes,odd_change,oddbase,oddfin,prob1step)
c
write.xlsx(c, "C:/Users/ASUS/Documents/odd4.xlsx")

#crea el pronostico base de entrenamiento
prontrain_both<-ifelse(steplogit_both$fitted.values > 0.65,1,0)
both$Incumplimiento<-as.factor(both$Incumplimiento)
conftrain_both<-confusionMatrix(as.factor(prontrain_both),both$Incumplimiento, positive = "1")
conftrain_both$table
conftrain_both$byClass
conftrain_both$overall

a<-cbind(a,conftrain_both$byClass)

#crea el pronóstico en validación
probtest_both<-predict(steplogit_both,newdata = score.test,type='response')
prontest_both<-ifelse(probtest_both > 0.65,1,0)
conftest_both<-confusionMatrix(as.factor(prontest_both),score.test$Incumplimiento, positive = "1")
conftest_both$table
conftest_both$byClass
conftest_both$overall

a<-cbind(a,conftest_both$byClass)

###############################



#2.4 oversampling con SMOTE

###############################
score.train$Incumplimiento<-as.factor(score.train$Incumplimiento)
smote2 <- ubSMOTE(score.train[,1:7],score.train$Incumplimiento, perc.over = 100, perc.under = 300)

table(smote2$Y)
a0<-as.matrix(smote2$X)
b0<-as.matrix(smote2$Y)

b1<-as.data.frame(as.numeric(b0))
smote1<-as.data.frame(cbind(a0,b1))

colnames(smote1)[8]<-"Incumplimiento"

modelo.logit_smote<-glm(Incumplimiento~.,family=binomial,smote1)
steplogit_smote<-step(modelo.logit_smote, direction="both", trace=0)
summary(steplogit_smote)


table(prontrain_smote)

set.seed(1)
smote1 <- SMOTE(Incumplimiento~., score.train, perc.over = 100, perc.under = 300)
table(smote1$Incumplimiento)
summary(smote1)

modelo.logit_smote<-glm(Incumplimiento~.,family=binomial,smote1)
steplogit_smote<-step(modelo.logit_smote, direction="both", trace=0)
summary(steplogit_smote)


coeficientes<-steplogit_both$coefficients
odd_change<-exp(coeficientes)
odd_change
balance<-table(smote1$Incumplimiento)
prop.table(balance)
oddbase<-prop.table(balance)[2]/prop.table(balance)[1]
oddbase

oddfin<-oddbase*odd_change
prob1step<-oddfin/(1+oddfin)
prob1step
c<-cbind(coeficientes,odd_change,oddbase,oddfin,prob1step)
c
write.xlsx(c, "C:/Users/ASUS/Documents/odd4.xlsx")



prontrain_smote<-ifelse(steplogit_smote$fitted.values > 0.65,1,0)
prontrain_smote<-as.factor(prontrain_smote)
smote1$Incumplimiento<-as.factor(smote1$Incumplimiento)
conftrain_smote<-confusionMatrix(prontrain_smote,smote1$Incumplimiento, positive = "1")

conftrain_smote$table
conftrain_smote$byClass
conftrain_smote$overall
#crea el pronóstico en validación
probtest_smote<-predict(steplogit_smote,newdata = score.test)

prontest_smote<-ifelse(probtest_smote > 0.65,1,0)

conftest_smote<-confusionMatrix(as.factor(prontest_smote),score.test$Incumplimiento, positive = "1")
conftest_smote$table
conftest_smote$byClass
conftest_smote$overall
table(smote1$Incumplimiento)
table(score.train$Incumplimiento)
###############################

write.xlsx(a, "C:/Users/ASUS/Documents/ResulMode.xlsx")


library(ROCR)
#crear objeto de predicciones
pr<-prediction(probtest,score.test$Incumplimiento)
#creacion del objeto de la curva
curvaROC<-performance(pr,measure="tpr",x.measure="fpr")
#grafico de la curva
plot(curvaROC)

library(caret)
# creo parámetros de validación cruzada
cross<-trainControl(method="cv",number=10)
modeloknn1<-train(Incumplimiento~.,method="knn",
                  tuneGrid=expand.grid(k=1:10),
                  trControl=cross, 
                  metric="F",
                  data=score.train)
modeloknn1



#correr el modelo en la bd load
score_upload <- read_excel("score-test.xlsx")

score_upload$Empleado <-factor(score_upload$Empleado)
#convertir variables en dummies

#score_upload_dummies<-dummyVars("~.",data=score_upload)
#score_upload_dummies_fin<-as.data.frame(predict(score_upload_dummies,newdata=score_upload))
#eliminar una variable Empleado para evitar multicolinealidad

score_upload_fin<-within(score_upload,rm(id))


str(score_upload_fin)
str(score_fin)
probupload_smote<-predict(steplogit_smote,newdata = score_upload_fin)
pronupload_smote<-ifelse(probupload_smote > 0.6,1,0)
pronupload_smote
score_upload$Incumplimiento <- pronupload_smote
table(score_upload$Incumplimiento)
write.csv(score_upload,"salida_f1.csv")


write.csv(score.train,"train60.csv")
