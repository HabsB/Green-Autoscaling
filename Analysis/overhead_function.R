library(tidyverse)
library(bayestestR)
library(car)
library(dplyr)
library(ggplot2)
library(gridExtra)
library(svglite)
library(bestNormalize)
library(effectsize)


data1 = read.csv('C:/Users/tihan/OneDrive/Desktop/Thesis/Data/Analysis/fixed function sorted.csv')
  
data2 = read.csv('C:/Users/tihan/OneDrive/Desktop/Thesis/fixed function sorted.csv')
data2

#Plot Function line graph for both treatments according to number of microservices
with_wl <- data1[data1$Workload == 'With', ]
without_wl <- data1[data1$Workload == 'Without', ]
with_wl
without_wl

with_wl_tot <- with_wl %>%
  mutate(total_energy = (PKG_Energy + DRAM_Energy))
with_wl_tot

without_wl_tot <- without_wl %>%
  mutate(total_energy = (PKG_Energy + DRAM_Energy))
without_wl_tot

with_wl <- datao[datao$Workload == 'With', ]

datat <- with_wl[with_wl$Trial == '2', ]
datam <- datat[datat$Microservices == '1', ]

datao <- data1 %>%
  mutate(total_energy = (PKG_Energy + DRAM_Energy))

data <- datat %>% group_by(Microservices) %>% summarise(total_energy=sum(total_energy))
data
# Sum Energy cost of all components with and without workload
with_wl_tot <- with_wl_tot %>% group_by(Microservices) %>% summarise(total_energy = sum(total_energy))
without_wl_tot <- without_wl_tot %>% group_by(Microservices) %>% summarise(total_energy = sum(total_energy))
with_wl_tot
without_wl_tot

data
without_wl_tot <- without_wl_tot %>%
  mutate(Workload = ("Without"))
data <- list(with_wl_tot, without_wl_tot)
data <- data %>% reduce(full_join)

write.csv(data, "C:/Users/tihan/OneDrive/Desktop/Thesis/Data/Analysis/CAKA_Vs_Microservices.csv", row.names=FALSE)
with_wl_tot
without_wl_tot





par(mfrow=c(1,1))
plot(with_wl_tot$total_energy ~ without_wl_tot$Microservices, ylim=c(26,27.5), xlab="No of Microservices", ylab="Energy Consumption(j)", type = "l", lwd=2.5 ) # Equivalent
lines(without_wl_tot$total_energy ~ without_wl_tot$Microservices, type = "l", col = 2, lwd=2.5)
legend("topright", c("With workload", "Without workload"),
       fill=c("black","red"), cex=1.0)


ggplot(data = data, aes(x = Microservices, y = total_energy, group = Workload)) +
  geom_line(aes(color = country), size = 2)




# Sum Energy cost of all components with and without workload
# with_wl_PKGT <- with_wl %>% group_by(Microservices) %>% summarise(PKG_Energy = sum(PKG_Energy))
# without_wl_PKGT <- without_wl %>% group_by(Microservices) %>% summarise(PKG_Energy = sum(PKG_Energy))
# with_wl_DRAMT <- with_wl %>% group_by(Microservices) %>% summarise(DRAM_Energy = sum(DRAM_Energy))
# without_wl_DRAMT <- without_wl %>% group_by(Microservices) %>% summarise(DRAM_Energy = sum(DRAM_Energy))
# with_wl_tot1
# without_wl_tot1
# 
# par(mfrow=c(1,1))
# plot(with_wl_PKGT$PKG_Energy ~ with_wl_PKGT$Microservices, type = "l") # Equivalent
# lines(without_wl_PKGT$PKG_Energy ~ without_wl_PKGT$Microservices, type = "l", col = 2)
# 
# par(mfrow=c(1,1))
# plot(with_wl_DRAMT$DRAM_Energy ~ with_wl_DRAMT$Microservices, type = "l") # Equivalent
# lines(without_wl_DRAMT$DRAM_Energy ~ without_wl_DRAMT$Microservices, type = "l", col = 2)
# 
# #plot function for Carbon Aware KEDA Operator component
# with_wl_cako <- with_wl_tot[with_wl$Components == 'Carbon-Aware-KEDA-Operator',]
# without_wl_cako <- without_wl_tot[without_wl$Components == 'Carbon-Aware-KEDA-Operator',]
# without_wl_cako
# with_wl_cako
# 
# par(mfrow=c(1,1))
# plot(with_wl_cako$PKG_Energy ~ with_wl_cako$Microservices, type = "l") # Equivalent
# lines(without_wl_cako$PKG_Energy ~ without_wl_cako$Microservices, type = "l", col = 2)
# 
# #plot function for KEDA
# with_wl_keda <- with_wl_tot[with_wl$Components == 'KEDA',]
# without_wl_keda <- without_wl_tot[without_wl$Components == 'KEDA',]
# without_wl_keda
# with_wl_keda
# 
# par(mfrow=c(1,1))
# plot(with_wl_keda$PKG_Energy ~ with_wl_keda$Microservices, type = "l") # Equivalent
# lines(without_wl_keda$PKG_Energy ~ without_wl_keda$Microservices, type = "l", col = 2)



# Organize Response Time related data
keda_data = datao[,c(
  "Components",
  "Workload",
  "Microservices",
  "total_energy"
)]

keda_data

keda_energy_by_microservices = keda_data %>%
  group_by(Microservices)

keda_energy_by_microservices_summary = keda_energy_by_microservices %>%
  summarize(
    count = n(),
    Minimum =round( min(total_energy),3),
    Q1 =round( quantile(total_energy, 0.25),3),
    Median =round( median(total_energy),3),
    Mean =round( mean(total_energy),3),
    SD =round( sd(total_energy),3),
    Q3 =round( quantile(total_energy, 0.75),3),
    Maximum =round(max(total_energy),3)
  )

keda_energy_by_microservices_summary

write.csv(
  keda_energy_by_microservices_summary,
  "C:/Users/tihan/OneDrive/Desktop/Thesis/Data/Analysis/cp/keda_energy_by_microservices_summary.csv",
  row.names = FALSE
)

class(data$Microservices)
data1
#box_plot_autoscaler_vs_energy_data_per_scenario
boxplot_keda_energy = ggplot(data1, aes(x=Microservices, y=total_energy, fill=Microservices)) +
  theme(axis.title = element_text(size = 10),
        plot.title = element_text(size = 12),
        legend.position = "bottom",
  ) +
  geom_boxplot(outlier.size=.4,) +
  labs(title="Energy Usage (J) Carbon Aware KEDA extra components as per number of Microservices", x="Number of Microservices", y="Energy Consumption(J)") +
  stat_summary(fun = mean, color = "grey", position = position_dodge(0.75),
               geom = "point", shape = 18, size = 2,
               show.legend = FALSE, aes(fill=factor(Microservices)))

boxplot_keda_energy

ggsave(
  file="C:/Users/tihan/OneDrive/Desktop/Thesis/Data/Analysis/Figures/Box_Plot/boxplot_keda_energy.png",
  plot=boxplot_keda_energy,
)

#box_plot_autoscaler_vs_energy_data_per_scenario
boxplot_keda_workload_energy = ggplot(data1, aes(x=Microservices, y=total_energy, fill=Workload)) +
  theme(axis.title = element_text(size = 10),
        plot.title = element_text(size = 12),
        legend.position = "bottom",
  ) +
  geom_boxplot(outlier.size=.4,) +
  labs(title="Energy Usage (J) Carbon Aware KEDA extra components Vs Microservices with/without workload", x="Number of Microservices", y="Energy Consumption(J)") +
  stat_summary(fun = mean, color = "grey", position = position_dodge(0.75),
               geom = "point", shape = 18, size = 3,
               show.legend = FALSE, aes(fill=factor(Workload)))

boxplot_keda_workload_energy

ggsave(
  file="C:/Users/tihan/OneDrive/Desktop/Thesis/Data/Analysis/Figures/Box_Plot/boxplot_keda_workload_energy.png",
  plot=boxplot_keda_workload_energy,
)

check_normality_data <- function(func_data, saveHistogram = FALSE, saveQQPlot = FALSE, normalized=FALSE) {
  par(mfrow=c(1,3))
  
  normalized_text = if(normalized) '_normalized' else ''
  
  if (saveHistogram) {
    png(paste("./overhead/histogram_energy_keda_consumption",normalized_text,".png", sep = ""))
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
    png(paste("./energy_results/qq_plot_energy_keda_consumption",normalized_text,".png", sep = ""))
    car::qqPlot(func_data, main="QQ Plot of Energy Consumption", xlab="Normality Quantiles", ylab="Samples")
    dev.off()
    car::qqPlot(func_data, main="QQ Plot of Energy Consumption", xlab="Normality Quantiles", ylab="Samples")
  } else {
    car::qqPlot(func_data, main="QQ Plot of Energy Consumption", xlab="Normality Quantiles", ylab="Samples")
  }
  
  shapiro_energy_test = shapiro.test(func_data) 
  print(shapiro_energy_test)
  
  capture.output(shapiro_energy_test, file = paste("./overhead/shapiro_energy_consumption_keda",normalized_text,".txt", sep=""))
  par(mfrow=c(1,1))
}

#check_normality_of_whole_data
check_normality_data(keda_data$total_energy, saveHistogram = TRUE)

#best normalize whole data
bestNormAvgEnergy = bestNormalize(keda_data$total_energy, out_of_sample = FALSE)
bestNormAvgEnergy
keda_data$norm_energy = bestNormAvgEnergy$x.t

#to confirm the data transformed in normally distributed
check_normality_data(keda_data$norm_energy, saveHistogram = TRUE, saveQQPlot = TRUE, normalized=TRUE)


# anova-analysis
energy_by_keda <- norm_energy ~ Microservices
res.aov_keda_energy <- aov(energy_by_keda, data = keda_data)
# Summary of the analysis
energy_sum_aov_keda = summary(res.aov_keda_energy)
energy_sum_aov_keda
capture.output(energy_sum_aov_keda, file = "./overhead/anova_one_way_keda_energy.txt")


# density plot for energy 
density_curve_energy_keda = ggplot(datao, aes(x=total_energy, color=Microservices, fill=Microservices)) +
  geom_density(alpha=0.3) +
  theme(axis.title = element_text(size = 10),
        plot.title = element_text(size = 14)
  ) +
  labs(title="Energy Consumption (Joule) for different microservices configurations", x="Energy Consumption (Joule)", y="Density")

density_curve_energy_keda

ggsave(
  file="./overhead/density_curve_energy_microservices.png",
  plot=density_curve_energy_autoscaler,
)