library(tidyverse)
library(bayestestR)
library(car)
library(dplyr)
library(ggplot2)
library(gridExtra)

data = read.csv('C:/Users/tihan/OneDrive/Desktop/Thesis/Data/Analysis/Benchmark_data.csv')
data

data2 = read.csv('C:/Users/tihan/OneDrive/Desktop/Thesis/fixed function sorted.csv')
data2


#Plot Function line graph for both treatments according to number of microservices
with_wl <- data2[data2$Workload == 'With', ]
without_wl <- data2[data2$Workload == 'Without', ]

with_wl_cako <- with_wl_cako %>%
  mutate(total_energy = (PKG_Energy + without_wl_cako$DRAM_Energy))
without_wl_cako

without_wl_cako <- without_wl_cako %>%
  mutate(total_energy = (PKG_Energy + without_wl_cako$DRAM_Energy))
without_wl_cako


with_wl_cako <- with_wl[with_wl$Components == 'Carbon-Aware-KEDA-Operator',]
without_wl_cako <- without_wl[without_wl$Components == 'Carbon-Aware-KEDA-Operator',]
without_wl_cako
with_wl_cako

par(mfrow=c(1,1))
plot(with_wl_cako$PKG_Energy ~ with_wl_cako$Microservices, type = "l") # Equivalent
lines(without_wl_cako$PKG_Energy ~ without_wl_cako$Microservices, type = "l", col = 2)

# other component
with_wl <- data2[data2$Workload == 'With', ]
without_wl <- data2[data2$Workload == 'Without', ]
with_wl_cako <- with_wl[with_wl$Components == 'Carbon Intensity Exporter',]
without_wl_cako <- without_wl[without_wl$Components == 'Carbon Intensity Exporter',]
without_wl_cako
with_wl_cako

with_wl_cako <- with_wl_cako %>%
  mutate(total_energy = (PKG_Energy + without_wl_cako$DRAM_Energy))
without_wl_cako

without_wl_cako <- without_wl_cako %>%
  mutate(total_energy = (PKG_Energy + without_wl_cako$DRAM_Energy))
without_wl_cako


par(mfrow=c(1,1))
plot(with_wl_cako$total_energy ~ with_wl_cako$Microservices, type = "l") # Equivalent
lines(without_wl_cako$total_energy ~ without_wl_cako$Microservices, type = "l", col = 2)



without_wl <- data2[data2$Workload == 'Without', ]
summary(data2)

Energy_box <- ggplot(data, aes(x=Microservices, y=DRAM_Energy, group= Microservices)) + 
  geom_boxplot(outlier.size = 1, width=0.5) + ylab("DRAM Energy (j)") + ggtitle("DRAM Energy (j), With different amount of microservices") + theme(plot.title = element_text(size=13, hjust = 0.3, face = "bold"))
DRAM_box <- DRAM_box + stat_summary(fun=mean, geom="point", shape=10, size=4) + theme(text = element_text(size = 13)) + scale_x_discrete(labels=c("1", "4", "8", "14")) + labs(x = "No of Microservices")

PKG_box <- ggplot(data2, aes(x=Microservices, y=PKG_Energy, group= Microservices)) + 
  geom_boxplot(outlier.size = 1, width=0.5) + ylab("PKG(CORE+UNCORE) Energy (j)") + ggtitle("PKG(CORE+UNCORE) Energy (j) Consumption With different amount of microservices") + theme(plot.title = element_text(size=13, hjust = 0.3, face = "bold"))
PKG_box <- PKG_box + stat_summary(fun=mean, geom="point", shape=10, size=4) + theme(text = element_text(size = 13)) + scale_x_discrete(labels=c("1", "4", "8", "14")) + labs(x = "No of Microservices")

DRAM_box_W <- ggplot(data2, aes(x=Microservices, y=DRAM_Energy, group= Microservices)) + 
  geom_boxplot(outlier.size = 1, width=0.5) + ylab("DRAM Energy (j)") + ggtitle("DRAM Energy (j), With different amount of microservices") + theme(plot.title = element_text(size=13, hjust = 0.3, face = "bold"))
DRAM_box_W <- DRAM_box_W + stat_summary(fun=mean, geom="point", shape=10, size=4) + theme(text = element_text(size = 13)) + scale_x_discrete(labels=c("1", "4", "8", "14")) + labs(x = "No of Microservices")

PKG_box_W <- ggplot(data2, aes(x=Workload, y=PKG_Energy, group= Workload)) + 
  geom_boxplot(outlier.size = 1, width=0.5) + ylab("PKG(CORE+UNCORE) Energy (j)") + ggtitle("PKG(CORE+UNCORE) Energy (j) Consumption With different amount of microservices") + theme(plot.title = element_text(size=13, hjust = 0.3, face = "bold"))
PKG_box_W <- PKG_box_W + stat_summary(fun=mean, geom="point", shape=10, size=4) + theme(text = element_text(size = 13)) + scale_x_discrete(labels=c("With", "Without")) + labs(x = "No of Microservices")


grid.arrange(DRAM_box_W, PKG_box_W, ncol=2)

#Transformation using log, square, and reciprocal
data_transformation <- function(data){
  transformed_data <- data %>%
    mutate(PKG_Energy_log = log(PKG_Energy),
           PKG_Energy_sqrt = sqrt(PKG_Energy),
           PKG_Energy_reciprocal = 1/PKG_Energy,
           DRAM_Energy_log = log(DRAM_Energy),
           DRAM_Energy_sqrt = sqrt(DRAM_Energy),
           DRAM_Energy_reciprocal = 1/DRAM_Energy)
  return(transformed_data)
}

#columns for transformed data
columns_transformeddata <- c('PKG_Energy_log', 'PKG_Energy_sqrt', 'PKG_Energy_reciprocal','DRAM_Energy_log', 'DRAM_Energy_sqrt',
                             'DRAM_Energy_reciprocal')


transformed_data <- data_transformation(data2) %>% 
  mutate_at(columns_transformeddata, as.numeric)

transformed_data

#transformed data for both with and without ads and analytics
transformed_with_wl <- data_transformation(with_wl) %>% 
  mutate_at(columns_transformeddata, as.numeric)
transformed_with_wl

#transformed data for both with and without ads and analytics
transformed_without_wl <- data_transformation(without_wl) %>% 
  mutate_at(columns_transformeddata, as.numeric)
transformed_without_wl

#density plots for both with/without ads and analytics
par(mfrow=c(3,2))
plot(density(transformed_with_wl$PKG_Energy), 
     xlab="PKG_Energy(%)", ylim=c(0, 0.40), col="red", main="Density plot for PKG_Energy(j) usage", 
     cex.main=1.5, cex.lab=1.2, cex.axis=1.0)
lines(density(transformed_without_wl$PKG_Energy), col="green")
legend("topright", c("With workload", "Without workload"),
       fill=c("red","green"), cex=1.0)
plot(density(transformed_with_wl$DRAM_Energy), 
     xlab="DRAM_Energy(%)", ylim=c(0, 1.4), col="red", main="Density plot for DRAM_Energy(j) usage", 
     cex.main=1.5, cex.lab=1.2, cex.axis=1.0)
lines(density(transformed_without_wl$DRAM_Energy), col="green")
legend("topright", c("With workload", "Without workload"),
       fill=c("red","green"), cex=1.0)


plot(density(transformed_with_wl$PKG_Energy_log), 
     xlab="log(PKG_Energy)", ylim=c(0, 3.8), col="red", main="Density plot for log(PKG_Energy) usage", 
     cex.main=1.5, cex.lab=1.2, cex.axis=1.0)
lines(density(transformed_without_wl$PKG_Energy_log), col="green")
legend("topright", c("With workload", "Without workload"),
       fill=c("red","green"), cex=1.0)
plot(density(transformed_with_wl$DRAM_Energy_sqrt), 
     xlab="sqrt(DRAM)", ylim=c(0, 1.8), col="red", main="Density plot for sqrt(DRAM) usage", 
     cex.main=1.5, cex.lab=1.2, cex.axis=1.0)
lines(density(transformed_without_wl$DRAM_Energy_sqrt), col="green")
legend("topright", c("With workload", "Without workload"),
       fill=c("red","green"), cex=1.0)



#normality check function
check_normality <- function(data, axis_text, variable){
  #par(mfrow=c(1,1.5))
  # plot(density(data), 
  #      xlab=axis_text, col="blue", 
  #      main=paste("Density plot of", variable),
  #      cex.main=1.3, cex.lab=1.5, cex.axis=1.2)
  car::qqPlot(data, main=paste('Q-Q plot of',variable), ylab=axis_text)
  print(shapiro.test(data))
}

par(mfrow=c(4,2))
check_normality(with_wl$DRAM_Energy , "DRAM_Energy(j)", "DRAM_Energy(j) with workload")
check_normality(transformed_with_wl$DRAM_Energy_log , "DRAM_Energy_log(j)", "DRAM_Energy(j) with workload")
check_normality(transformed_with_wl$DRAM_Energy_sqrt , "DRAM_Energy_sqrt(j)", "DRAM_Energy(j) with workload")
check_normality(transformed_with_wl$DRAM_Energy_reciprocal , "DRAM_Energy_reciprocal(j)", "DRAM_Energy(j) with workload")
check_normality(transformed_with_wl$PKG_Energy , "PKG_Energy(j)", "PKG_Energy(j) with workload")
check_normality(transformed_with_wl$PKG_Energy_log , "PKG_Energy_log(j)", "PKG_Energy(j) with workload")
check_normality(transformed_with_wl$PKG_Energy_sqrt , "PKG_Energy_sqrt(j)", "PKG_Energy(j) with workload")
check_normality(transformed_with_wl$PKG_Energy_reciprocal , "PKG_Energy_reciprocal(j)", "PKG_Energy(j) with workload")




# # Using the data of each microservices energy consumption
# summary(data)
# Energy_box <- ggplot(applicatoin_data, aes(x=Autoscaling, y=PKG_Energy, group= Autoscaling)) + 
#   geom_boxplot(outlier.size = 1, width=0.5) + ylab("Energy Consumption (j)") + ggtitle("Energy Consumption (j) With different Autoscalers") + theme(plot.title = element_text(size=13, hjust = 0.3, face = "bold"))
# Energy_box <- Energy_box + stat_summary(fun=mean, geom="point", shape=10, size=4) + theme(text = element_text(size = 13)) + scale_x_discrete(labels=c("Carbon Aware KEDA", "HPA Based" )) + labs(x = "Autoscalers")
# 
# RT_box <- ggplot(data, aes(x=Autoscaling, y=Response_Time, group= Autoscaling)) + 
#   geom_boxplot(outlier.size = 1, width=0.5) + ylab("Response  Time (ms)") + ggtitle("Response  Time (ms) With different Autoscalers") + theme(plot.title = element_text(size=13, hjust = 0.3, face = "bold"))
# RT_box <- RT_box + stat_summary(fun=mean, geom="point", shape=10, size=4) + theme(text = element_text(size = 13)) + scale_x_discrete(labels=c("Carbon Aware KEDA", "HPA Based")) + labs(x = "Autoscalers")
# 
# 
# # Using the total consumption and average response time of the overall application
# summary(data_cako)
# Energy_box <- ggplot(both_scalers_merged, aes(x=Autoscaling, y=PKG_Energy, group= Autoscaling)) + 
#   geom_boxplot(outlier.size = 1, width=0.5) + ylab("Energy Consumption (j)") + ggtitle("Energy Consumption (j) With different Autoscalers") + theme(plot.title = element_text(size=13, hjust = 0.3, face = "bold"))
# Energy_box <- Energy_box + stat_summary(fun=mean, geom="point", shape=10, size=4) + theme(text = element_text(size = 13)) + scale_x_discrete(labels=c("Carbon Aware KEDA", "HPA Based" )) + labs(x = "Autoscalers")
# 
# RT_box <- ggplot(both_scalers_merged, aes(x=Autoscaling, y=Response_Time, group= Autoscaling)) + 
#   geom_boxplot(outlier.size = 1, width=0.5) + ylab("Response  Time (ms)") + ggtitle("Response  Time (ms) of app With different Autoscalers") + theme(plot.title = element_text(size=13, hjust = 0.3, face = "bold"))
# RT_box <- RT_box + stat_summary(fun=mean, geom="point", shape=10, size=4) + theme(text = element_text(size = 13)) + scale_x_discrete(labels=c("Carbon Aware KEDA", "HPA Based")) + labs(x = "Autoscalers")



# #Transformation using log, square, and reciprocal
# data_transformation <- function(data){
#   transformed_data <- data %>%
#     mutate(PKG_Energy_log = log(PKG_Energy),
#            PKG_Energy_sqrt = sqrt(PKG_Energy),
#            PKG_Energy_reciprocal = 1/PKG_Energy,
#            Respons_Time_log = log(Response_Time),
#            Respons_Time_sqrt = sqrt(Response_Time),
#            Respons_Time_reciprocal = 1/Response_Time)
#   return(transformed_data)
# }
# 
# #columns for transformed data
# columns_transformeddata <- c('PKG_Energy_log', 'PKG_Energy_sqrt', 'PKG_Energy_reciprocal','Respons_Time_log', 'Respons_Time_sqrt',
#                              'Respons_Time_reciprocal')
# 
# 
# transformed_hpa_data <- data_transformation(data_benchmark) %>% 
#   mutate_at(columns_transformeddata, as.numeric)
# 
# transformed_hpa_data
# 
# transformed_cako_data <- data_transformation(data_cako) %>% 
#   mutate_at(columns_transformeddata, as.numeric)
# 
# transformed_cako_data
# 
# # Response Time data transformation
# transformed_data_benchmark_RP <- data_transformation(data_benchmark_RP) %>%
#   mutate_at(columns_transformeddata, as.numeric)
# 
# transformed_data_benchmark_RP
# 
# transformed_data_cako_RP <- data_transformation(data_cako_RP) %>%
#  mutate_at(columns_transformeddata, as.numeric)
# 
# transformed_data_cako_RP
# 
# 
# 
# 
# 
# #density plots for both autoscalers
# par(mfrow=c(1,1))
# plot(density(transformed_data_benchmark_RP$PKG_Energy), 
#      xlab="Energy(j)", ylim=c(0, 0.09), col="red", main="Density plot for Energy(j) usage", 
#      cex.main=1.5, cex.lab=1.2, cex.axis=1.0)
# lines(density(transformed_data_cako_RP$PKG_Energy), col="green")
# legend("topright", c("HPA Based ", "Carbon Aware KEDA"),
#        fill=c("red","green"), cex=0.8)
# 
# plot(density(transformed_data_benchmark_RP$Response_Time), 
#      xlab="Response Time(ms)", ylim=c(0, 0.006), col="red", main="Density plot for Response Time(ms)", 
#      cex.main=1.5, cex.lab=1.2, cex.axis=1.0)
# lines(density(transformed_data_cako_RP$Response_Time), col="green")
# legend("topright", c("HPA Based", "Carbon Aware KEDA"),
#        fill=c("red","green"), cex=1.0)


# 
# #normality check function
# check_normality <- function(data, axis_text, variable){
#   #par(mfrow=c(2,1))
#   #plot(density(data), 
#        #xlab=axis_text, col="blue", 
#        #main=paste("Density plot of", variable),
#         #cex.main=1.3, cex.lab=1.5, cex.axis=1.2)
#   car::qqPlot(data, main=paste('Q-Q plot of',variable), ylab=axis_text)
#   print(shapiro.test(data))
# }
# 
# #Normality check for ads and analytics along with its transformation
# par(mfrow=c(1,1))
# check_normality(transformed_hpa_data$PKG_Energy , "Energy(j)", "Energy(j) of HPA Based Autoscaler")
# check_normality(transformed_data_benchmark_RP$Response_Time , "Energy(j)", "Energy(j) of Carbon Aware KEDA Autoscaler")
# 



components_csvpaths <- list.files(path = "C:/Users/tihan/OneDrive/Desktop/Thesis/Data/Function", 
                                    recursive = TRUE, pattern="\\.csv", full.names = TRUE)

components_csvpaths
app.data <- components_csvpaths %>%
  lapply(read.csv)%>%
  bind_rows()

app.data

length(green_csvpaths_energy)

column_names <- c("Type", "Pod name", "Browser", "CPU", "Memory", "Energy consumption")
