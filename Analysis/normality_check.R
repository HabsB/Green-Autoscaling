library(tidyverse)
library(bayestestR)
library(car)
library(dplyr)
library(ggplot2)
library(gridExtra)
library(svglite)
library(bestNormalize)
library(effectsize)
library(ggpubr)
library(lsr)



# Read CSV Data of HPA based, Carbon Aware KEDA and combined data
data_benchmark = read.csv('./Data/data_benchmark_final.csv')
data_cako = read.csv('./Data/data_cako_final.csv')
data_benchmark2 = read.csv('./Data/data_benchmark2_final.csv')
data_cako2 = read.csv('./Data/data_cako2_final.csv')
both_scalers_merged = read.csv('./Data/both_scalers_merged_final.csv')
both_scalers_merged2 = read.csv('./Data/both_scalers_merged2_final.csv')

data_benchmark2 <- data_benchmark2 %>%
  mutate(Scenario = "Read_Intensive")


write.csv(
  data_benchmark2,
  "C:/Users/tihan/OneDrive/Desktop/Thesis/Data/Analysis/cp/data_benchmark2_final.csv",
  row.names = FALSE
)

data_benchmark <- data_benchmark[data_benchmark$Test == '1', ]
data_cako2 <- data_cako2 %>% group_by(Test) %>% summarise(PKG_Energy=sum(PKG_Energy))
data


# Response Time Data
both_scalers_merged <- both_scalers_merged %>% drop_na()
both_scalers_merged2 <- both_scalers_merged2 %>% drop_na()

data_list_rt <- list(both_scalers_merged, both_scalers_merged2)
data_rt <- data_list_rt %>% reduce(full_join)

# data_rt

#put all data frames into list
data_list <- list(data_benchmark, data_cako, data_benchmark2, data_cako2)

#merge all data frames in list
data <- data_list %>% reduce(full_join)
data

# Save the combined data into CSV file
write.csv(data, "C:/Users/tihan/OneDrive/Desktop/Thesis/Data/Analysis/cp/fina_dataset_energy.csv", row.names=FALSE)
write.csv(data_rt, "C:/Users/tihan/OneDrive/Desktop/Thesis/Data/Analysis/cp/final_RT_dataset.csv", row.names=FALSE)


# Organize Energy related data
energy_data = data[,c(
  "Microservice",
  "Test",
  "Autoscaling",
  "Scenario",
  "PKG_Energy"
)]

energy_data



# Organize Response Time related data
application_data = data_rt[,c(
  "Test",
  "Autoscaling",
  "Scenario",
  "Response_Time",
  "PKG_Energy"
)]

application_data



# Organize Result
#Energy consumption comparison - RQ2
# Application Energy consumption 
energy_by_autoscaler = energy_data %>%
  group_by(Autoscaling)

energy_by_Autoscalers_summary = energy_by_autoscaler %>%
  summarize(
    count = n(),
    Minimum =round( min(PKG_Energy),3),
    Q1 =round( quantile(PKG_Energy, 0.25),3),
    Median =round( median(PKG_Energy),3),
    Mean =round( mean(PKG_Energy),3),
    SD =round( sd(PKG_Energy),3),
    Q3 =round( quantile(PKG_Energy, 0.75),3),
    Maximum =round(max(PKG_Energy),3)
  )

energy_by_Autoscalers_summary

write.csv(
  energy_by_Autoscalers_summary,
  "./energy_results/qq_plot_energy_app_consumption/app_energy_by_Autoscalers_summary.csv",
  row.names = FALSE
)
application_data

#box_plot_autoscaler_vs_energy_data_per_scenario
boxplot_scenario_energy = ggplot(application_data, aes(x=Scenario, y=PKG_Energy, fill=Autoscaling)) +
  theme(axis.title = element_text(size = 10),
        plot.title = element_text(size = 12),
        legend.position = "bottom",
  ) +
  geom_boxplot(outlier.size=.4,) +
  labs(title="Energy Usage (J) of Sock Shop as per Workload Scenario Tested", x="Microservices", y="Energy Consumption(J)") +
  stat_summary(fun = mean, color = "grey", position = position_dodge(0.75),
               geom = "point", shape = 18, size = 2,
               show.legend = FALSE, aes(fill=factor(Autoscaling)))

boxplot_scenario_energy

ggsave(
  file="C:/Users/tihan/OneDrive/Desktop/Thesis/Data/Analysis/cp/Box_Plot/boxplot_scenario_energy.png",
  plot=boxplot_scenario_energy,
)

#box_plot_application_vs_energy_data_per_autoscaler
boxplot_application_energy = ggplot(application_data, aes(x=Autoscaling, y=PKG_Energy, fill=Autoscaling)) +
  theme(axis.title = element_text(size = 10),
        plot.title = element_text(size = 12),
        legend.position = "bottom",
  ) +
  geom_boxplot(outlier.size=.4,) +
  labs(title="Energy Usage (J) of Sock Shop as per the Autoscaling strategy emplyed", x="Autoscaling", y="Energy Consumption(Joule)") +
  stat_summary(fun = mean, color = "grey", position = position_dodge(0.75),
               geom = "point", shape = 18, size = 2,
               show.legend = FALSE, aes(fill=factor(Autoscaling)))

boxplot_application_energy

ggsave(
  file="C:/Users/tihan/OneDrive/Desktop/Thesis/Data/Analysis/cp/Box_Plot/boxplot_application_energy.png",
  plot=boxplot_application_energy,
)

energy_data

#box_plot_autoscaler_vs_energy_data_per_microservice
boxplot_microservice_autoscaling_energy = ggplot(energy_data, aes(x=Microservice, y=PKG_Energy, fill=Autoscaling)) +
  theme(axis.title = element_text(size = 10),
        plot.title = element_text(size = 12),
        legend.position = "bottom",
  ) +
  geom_boxplot(outlier.size=.4,) +
  labs(title="Energy Usage (J) of microservices in Sock Shop as per Autocaling employed", x="Microservices", y="Energy Consumption(J)") +
  stat_summary(fun = mean, color = "grey", position = position_dodge(0.75),
               geom = "point", shape = 18, size = 2,
               show.legend = FALSE, aes(fill=factor(Autoscaling)))

boxplot_microservice_autoscaling_energy

ggsave(
  file="C:/Users/tihan/OneDrive/Desktop/Thesis/Data/Analysis/cp/Box_Plot/boxplot_microservice_autoscaling_energy.png",
  plot=boxplot_microservice_autoscaling_energy,
)


check_normality_data <- function(func_data, saveHistogram = FALSE, saveQQPlot = FALSE, normalized=FALSE) {
  par(mfrow=c(1,3))
  
  normalized_text = if(normalized) '_normalized' else ''
  
  if (saveHistogram) {
    png(paste("./energy_results/histogram_app_energy_consumption",normalized_text,".png", sep = ""))
    func_data %>%
      hist(breaks=20,main="Energy Consumption Distribution")
    dev.off()
    func_data %>%
      hist(breaks=20,main="Energy Consumption Distribution")
  } else {
    func_data %>%
      hist(breaks=20,main="Energy Consumption Distribution")
  }
  
  if (saveQQPlot) {
    png(paste("./energy_results/qq_plot_energy_app_consumption",normalized_text,".png", sep = ""))
    car::qqPlot(func_data, main="QQ Plot of Energy Consumption", xlab="Normality Quantiles", ylab="Samples")
    dev.off()
    car::qqPlot(func_data, main="QQ Plot of Energy Consumption", xlab="Normality Quantiles", ylab="Samples")
  } else {
    car::qqPlot(func_data, main="QQ Plot of Energy Consumption", xlab="Normality Quantiles", ylab="Samples")
  }
  
  shapiro_energy_test = shapiro.test(func_data) 
  print(shapiro_energy_test)
  
  capture.output(shapiro_energy_test, file = paste("./energy_results/shapiro_energy_consumption",normalized_text,".txt", sep=""))
  par(mfrow=c(1,1))
}
energy_data
#check_normality_of_whole_data
check_normality_data(energy_data$PKG_Energy, saveHistogram = TRUE)
check_normality_data(application_data$PKG_Energy, saveHistogram = TRUE)

#best normalize whole data
bestNormAvgEnergy = bestNormalize(application_data$PKG_Energy, out_of_sample = FALSE)
bestNormAvgEnergy
energy_data$norm_energy = bestNormAvgEnergy$x.t

#check_normality_of_application_data
check_normality_data(energy_data$norm_energy, saveHistogram = TRUE)

#best normalize whole data
bestNormAvgEnergy = bestNormalize(application_data$PKG_Energy)
bestNormAvgEnergy
energy_data$norm_energy = bestNormAvgEnergy$x.t

#to confirm the data transformed in normally distributed
check_normality_data(application_data$norm_energy, saveHistogram = TRUE, saveQQPlot = TRUE, normalized=TRUE)



# # anova-analysis
energy_by_app_autoscaler <- PKG_Energy ~ Autoscaling
energy_by_app_autoscaler


#t_test_for_two_variables
res.t_test_scalers_app_energy = t.test(energy_by_app_autoscaler, data = application_data, alternative = "two.sided", var.equal = FALSE)
res.t_test_scalers_app_energy
capture.output(res.t_test_scalers_app_energy, file = "./energy_results/t_test_autoscaling_app_energy.txt")

# Calculating the effect size 
cohens_d(energy_by_app_autoscaler, data = application_data)

capture.output(res, file = "./energy_results/cohensD_energy.txt")

# density plot for energy 
density_curve_energy_autoscaler = ggplot(energy_data, aes(x=PKG_Energy, color=Autoscaling, fill=Autoscaling)) +
  geom_density(alpha=0.3) +
  theme(axis.title = element_text(size = 10),
        plot.title = element_text(size = 14)
  ) +
  labs(title="Energy Consumption (Joule) for both Autoscalers", x="Energy Consumption (Joule)", y="Density")

density_curve_energy_autoscaler

ggsave(
  file="./energy_results/density_curve_energy_autoscaler.png",
  plot=density_curve_energy_autoscaler,
)



# RQ#3

response_time_autoscaler = application_data %>%
  group_by(Autoscaling)

response_time_autoscaler_summary = response_time_autoscaler %>%
  summarize(
    count = n(),
    Minimum =round( min(Response_Time),3),
    Q1 =round( quantile(Response_Time, 0.25),3),
    Median =round( median(Response_Time),3),
    Mean =round( mean(Response_Time),3),
    SD =round( sd(Response_Time),3),
    Q3 =round( quantile(Response_Time, 0.75),3),
    Maximum =round(max(Response_Time),3)
  )

response_time_autoscaler_summary

write.csv(
  response_time_autoscaler_summary,
  "C:/Users/tihan/OneDrive/Desktop/Thesis/Data/Analysis/Data/response_time_autoscaler_summary.csv",
  row.names = FALSE
)

#box_plot_application_vs_response_time_data_per_autoscaler
boxplot_application_response_time = ggplot(application_data, aes(x=Autoscaling, y=Response_Time, fill=Autoscaling)) +
  theme(axis.title = element_text(size = 10),
        plot.title = element_text(size = 12),
        legend.position = "bottom",
  ) + 
  geom_boxplot(outlier.size=.4,) +
  labs(title="Response Time (ms) of Sock Shop as per the Autoscaling strategy emplyed", x="Autoscaling", y="Response Time(ms)") +
  stat_summary(fun = mean, color = "grey", position = position_dodge(0.75),
               geom = "point", shape = 18, size = 2,
               show.legend = FALSE, aes(fill=factor(Autoscaling)))

boxplot_application_response_time

ggsave(
  file="C:/Users/tihan/OneDrive/Desktop/Thesis/Data/Analysis/Figures/Box_Plot/boxplot_application_response_time.png",
  plot=boxplot_application_response_time,
)

#box_plot_autoscaler_vs_energy_data_per_scenario
boxplot_scenario_response_time = ggplot(application_data, aes(x=Scenario, y=Response_Time, fill=Autoscaling)) +
  theme(axis.title = element_text(size = 10),
        plot.title = element_text(size = 12),
        legend.position = "bottom",
  ) +
  geom_boxplot(outlier.size=.4,) +
  labs(title="Response Time (ms) of Sock Shop as per Workload Scenario Tested", x="Microservices", y="Energy Consumption(J)") +
  stat_summary(fun = mean, color = "grey", position = position_dodge(0.75),
               geom = "point", shape = 18, size = 2,
               show.legend = FALSE, aes(fill=factor(Autoscaling)))

boxplot_scenario_response_time

ggsave(
  file="C:/Users/tihan/OneDrive/Desktop/Thesis/Data/Analysis/Figures/Box_Plot/boxplot_scenario_response_time.png",
  plot=boxplot_scenario_response_time,
)


check_normality_data <- function(func_data, saveHistogram = FALSE, saveQQPlot = FALSE, normalized=FALSE) {
  par(mfrow=c(1,3))
  
  normalized_text = if(normalized) '_normalized' else ''
  
  if (saveHistogram) {
    png(paste("./energy_results/histogram_response_time",normalized_text,".png", sep = ""))
    func_data %>%
      hist(breaks=20,main="Response Time Distribution")
    dev.off()
    func_data %>%
      hist(breaks=20,main="Response Time Distribution")
  } else {
    func_data %>%
      hist(breaks=20,main="Response Time Distribution")
  }
  
  if (saveQQPlot) {
    png(paste("./energy_results/qq_plot_response_time",normalized_text,".png", sep = ""))
    car::qqPlot(func_data, main="QQ Plot of Response Time", xlab="Normality Quantiles", ylab="Samples")
    dev.off()
    car::qqPlot(func_data, main="QQ Plot of Response Time", xlab="Normality Quantiles", ylab="Samples")
  } else {
    car::qqPlot(func_data, main="QQ Plot of Response Time", xlab="Normality Quantiles", ylab="Samples")
  }
  
  shapiro_energy_test = shapiro.test(func_data) 
  print(shapiro_energy_test)
  
  capture.output(shapiro_energy_test, file = paste("./energy_results/shapiro_response_consumption",normalized_text,".txt", sep=""))
  par(mfrow=c(1,1))
}

#check_normality_of_response_time_data
check_normality_data(application_data$Response_Time, saveHistogram = TRUE)
application_data

#best normalize whole data
bestNormAvgEnergy = bestNormalize(application_data$Response_Time, out_of_sample = FALSE)
bestNormAvgEnergy
application_data$norm_energy = bestNormAvgEnergy$x.t

#check_normality_of_application_data
check_normality_data(application_data$norm_energy, saveHistogram = TRUE)

# Corroletion Analysis between Energy usage and Response Time
res <- cor.test(application_data$PKG_Energy, application_data$Response_Time, 
                method=c("pearson", "kendall", "spearman"))

res <- cor.test(application_data$PKG_Energy, application_data$Response_Time, 
                method = "pearson")
res

capture.output(res, file = "./energy_results/correlation_energy_response.txt")



energy_by_app_response <- Response_Time ~ Autoscaling
energy_by_app_response

#t_test_for_two_variables
res.t_test_scalers_app_response = t.test(energy_by_app_response, data = application_data, alternative = "two.sided", var.equal = FALSE)
res.t_test_scalers_app_response
capture.output(res.t_test_scalers_app_energy, file = "./energy_results/t_test_autoscaling_response_app.txt")

# Calculating the effect size 
cohens_d(energy_by_app_response, data = application_data)

capture.output(res, file = "./energy_results/cohensD_response.txt")

# density plot for energy 
density_curve_response_time_autoscaler = ggplot(application_data, aes(x=Response_Time, color=Autoscaling, fill=Autoscaling)) +
  geom_density(alpha=0.3) +
  theme(axis.title = element_text(size = 10),
        plot.title = element_text(size = 14)
  ) +
  labs(title="Response Time (ms) of Sock Shop as per Autoscaler employed", x="Response Time (ms)", y="Density")

density_curve_response_time_autoscaler

ggsave(
  file="./energy_results/density_curve_response_time_autoscaler.png",
  plot=density_curve_response_time_autoscaler,
)


