# First lets add all the libraries necessary for our analysis

library("readr")     
library("tidyverse")  
library("ggplot2")     
library("lubridate")    
library("geosphere")    
library("gridExtra")  
library("dplyr")         
library("skimr")
library("rmdformats")
library("png")
library("patchwork")
# Load all the data and check if column names match and others first-looking errors
datatrip_2020_09 <- read.csv("R docs/09.2020_09.2022 Data Cyclistic, Case of Study/202009-divvy-tripdata.csv")
datatrip_2020_10 <- read.csv("R docs/09.2020_09.2022 Data Cyclistic, Case of Study/202010-divvy-tripdata.csv")
datatrip_2020_11 <- read.csv("R docs/09.2020_09.2022 Data Cyclistic, Case of Study/202011-divvy-tripdata.csv")

# Until here end_station_id & start_station_id were int type, this needs to be correct (to chr type)

datatrip_2020_12 <- read.csv("R docs/09.2020_09.2022 Data Cyclistic, Case of Study/202012-divvy-tripdata.csv")
glimpse(datatrip_2020_12)
datatrip_2022_01 <- read.csv("R docs/09.2020_09.2022 Data Cyclistic, Case of Study/202201-divvy-tripdata.csv")
datatrip_2022_02 <- read.csv("R docs/09.2020_09.2022 Data Cyclistic, Case of Study/202202-divvy-tripdata.csv")
datatrip_2022_03 <- read.csv("R docs/09.2020_09.2022 Data Cyclistic, Case of Study/202203-divvy-tripdata.csv")
datatrip_2022_04 <- read.csv("R docs/09.2020_09.2022 Data Cyclistic, Case of Study/202204-divvy-tripdata.csv")
datatrip_2022_05 <- read.csv("R docs/09.2020_09.2022 Data Cyclistic, Case of Study/202205-divvy-tripdata.csv")
datatrip_2022_06 <- read.csv("R docs/09.2020_09.2022 Data Cyclistic, Case of Study/202206-divvy-tripdata.csv")
datatrip_2022_07 <- read.csv("R docs/09.2020_09.2022 Data Cyclistic, Case of Study/202207-divvy-tripdata.csv")
datatrip_2022_08 <- read.csv("R docs/09.2020_09.2022 Data Cyclistic, Case of Study/202208-divvy-tripdata.csv")
datatrip_2022_09 <- read.csv("R docs/09.2020_09.2022 Data Cyclistic, Case of Study/202209-divvy-tripdata.csv")

# Changing the data type for 2 columns (end_station_id & start_station_id)

datatrip_int <- bind_rows(datatrip_2020_09, datatrip_2020_10, datatrip_2020_11)
datatrip_chr_2020 <- datatrip_int %>% 
  mutate(start_station_id = as.character(start_station_id),
         end_station_id = as.character(end_station_id))

datatrip_chr_2022 <- bind_rows(datatrip_2020_12, datatrip_2022_01, datatrip_2022_02, datatrip_2022_03, datatrip_2022_04, 
                               datatrip_2022_05, datatrip_2022_06, datatrip_2022_07, datatrip_2022_08, datatrip_2022_09)

# Now that our data type match, lets join all the tables

all_datatrip <- bind_rows(datatrip_chr_2020, datatrip_chr_2022)

# Lets take a first look to our data (get to know your data)   (5.902.391 rows)
glimpse(all_datatrip)
skim_without_charts(all_datatrip)

# Start cleaning

# Droping NA values        (5.778.410 values left)
all_datatrip_drop <- drop_na(all_datatrip)

# Lets reduce the number of rows randomly for efficient proposes (better if not, depends of your computer)

all_datatrip_analysis <- all_datatrip_drop %>% slice_sample(prop = .01)

# Lets make the data time useful and few useful columns

all_datatrip_analysis$date <- as.Date(all_datatrip_analysis$started_at)
all_datatrip_analysis$month <- format(as.Date(all_datatrip_analysis$date), "%m")
all_datatrip_analysis$day <- format(as.Date(all_datatrip_analysis$date), "%d")
all_datatrip_analysis$year <- format(as.Date(all_datatrip_analysis$date), "%Y")
all_datatrip_analysis$day_of_week <- format(as.Date(all_datatrip_analysis$date), "%A")

all_datatrip_analysis$started_at_format <- as.POSIXlt(all_datatrip_analysis$started_at)

# Ended_at is not on property format, needs adjust 

all_datatrip_analysis$ended_at_format <- strptime(all_datatrip_analysis$ended_at, format="%Y-%m-%d %H:%M:%S")

# Rename the member type column, to make it understandable
colnames(all_datatrip_analysis)[colnames(all_datatrip_analysis)=="member_casual"] <- "type_member"

# Lets created new useful columns; speed, length rides and distances

# Ride length in minutes
all_datatrip_analysis$ride_length_min <- difftime(all_datatrip_analysis$ended_at_format, 
                                               all_datatrip_analysis$started_at_format, units="mins")

#Then the ride distance traveled in km
all_datatrip_analysis$ride_distance_km <- (distGeo(matrix(c(all_datatrip_analysis$start_lng, all_datatrip_analysis$start_lat), 
                            ncol = 2), matrix(c(all_datatrip_analysis$end_lng, all_datatrip_analysis$end_lat), ncol = 2))/1000)

# Lets clean all the entries with a negative ride length and also ride bike that were made for quality check by the company
all_datatrip_analysis <- all_datatrip_analysis[!(all_datatrip_analysis$start_station_name == "HQ QR" | 
                                                   all_datatrip_analysis$ride_length_min<0),]

# lets see the proportion between or two type of users

ggplot(data=subset(all_datatrip_analysis, !is.na(type_member)), aes(x=type_member)) + 
  geom_bar(mapping = aes(x=type_member, fill=type_member))

# There is trips with 0km distance, because of the constructions of our calculations, some bikes where return on the same place they were pick up.

all_datatrip_analysis[all_datatrip_analysis==0] <- NA
data_withou_0 <- drop_na(all_datatrip_analysis)

#Average distance by type users, without counting the rides with 0 km traveled

avr_user_type <- data_withou_0 %>% 
                group_by(type_member) %>% 
                 summarise(avr_distance = mean(ride_distance_km))

type_member_ride_length <- ggplot(data=subset (avr_user_type, !is.na(type_member)), aes(x=type_member)) + 
  geom_col(mapping=aes(x=type_member,y=avr_distance,fill=type_member), show.legend = FALSE)+
  labs(title = "Avr. travel distance by User",x="User Type",y="Avr. distance In Km",caption = "Data by Motivate International Inc")
type_member_ride_length

# Average ride length by type of user

avr_user_type2 <- data_withou_0 %>% 
  group_by(type_member) %>% 
  summarise(avr_time = mean(ride_length_min))

type_member_ride_time <- ggplot(data=subset (avr_user_type2, !is.na(type_member)), aes(x=type_member)) + 
   geom_col(mapping=aes(x=type_member,y=avr_time,fill=type_member), show.legend = FALSE)+
  labs(title = "Ride time by User type",x="User Type",y="Avg.ride time (minutes)",caption = "Data by Motivate International Inc")
type_member_ride_time

# lets graph both together

grid.arrange(type_member_ride_time, type_member_ride_length, ncol = 2)

# Frequency will be very informative, but is not possible, there is no rider id associate in the data

# Lets see the behave according to day of the week and user

all_datatrip_analysis$day_of_week <- factor(all_datatrip_analysis$day_of_week,
                                       levels = c("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"))
all_datatrip_analysis %>% 
  group_by(type_member, day_of_week) %>% 
  summarise(number_of_rides = n()
            ,average_duration = mean(ride_length_min),.groups = 'drop') %>% 
  arrange(type_member, day_of_week)

ggplot(data=subset (all_datatrip_analysis, !is.na(day_of_week)), aes(x=day_of_week)) +
  geom_bar(mapping =aes(x = day_of_week, fill = type_member),position = "dodge") +
  labs(title = "Number of rides by User type during the week",x="Days of the week",y="Number of rides",
       caption = "Data by Motivate International Inc", fill="User type") +
  theme(legend.position="top")

# (1)
  
# Now lets check the behave of the by user type according with type of bike and user
  
all_datatrip_analysis %>% 
    group_by(type_member, rideable_type) %>% 
    summarise(totals=n(), .groups="drop")  
  
ggplot(data=subset (all_datatrip_analysis, !is.na(type_member)), aes(x=type_member)) +
    geom_bar(mapping = aes(x= type_member, fill=rideable_type), position = "dodge") +
    labs(title = "Bike type usage by user type",x="User type",y=NULL, fill="Bike type") +
    scale_fill_manual(values = c("classic_bike" = "#2196f3", "docked_bike" = "#3E4144","electric_bike" = "#ff9800")) +
    theme_minimal() +
    theme(legend.position="top")
  
# Lets take docked bike out, lets see how this change depending of the day
  
all_datatrip_analysis_docked <- all_datatrip_analysis %>% filter(rideable_type=="classic_bike" | rideable_type=="electric_bike")
  
all_datatrip_analysis_docked$day_of_week <- factor(all_datatrip_analysis_docked$day_of_week,
                                              levels = c("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"))
  
all_datatrip_analysis_docked %>% 
    group_by(type_member,rideable_type,day_of_week) %>% 
    summarise(number_of_rides = n()) %>% 
    arrange(type_member, day_of_week)
  
ggplot(data=subset (all_datatrip_analysis_docked, !is.na(day_of_week)), aes(x=day_of_week)) +
    geom_bar(mapping =aes(x = day_of_week, fill = rideable_type),position = "dodge") +
    facet_wrap(~type_member) +
    labs(title = "Number of rides by User type during the week",x="Days of the week",y="Number of rides",
         caption = "Data by Motivate International Inc", fill="User type") +
    scale_fill_manual(values = c("classic_bike" = "#2196f3","electric_bike" = "#ff9800")) +
    theme(legend.position="top")

  
# (2)
  

# lets create maps with the most popular ride using Tableu,  to find interesting patterns
  
#First we need to create a table only for the most popular routes for casual and member users (200ride each)
  
coordinates_table_casual <- all_datatrip_analysis %>% 
    filter(start_lng != end_lng & start_lat != end_lat) %>%
    group_by(start_lng, start_lat, end_lng, end_lat, type_member, rideable_type) %>%
    summarise(total = n(),.groups="drop") %>%
    arrange (desc(total)) %>% 
    filter(type_member == "casual")
   
coordinates_table_casual_200 <- coordinates_table_casual[1:200, ]
  
  
coordinates_table_member <- all_datatrip_analysis %>% 
    filter(start_lng != end_lng & start_lat != end_lat) %>%
    group_by(start_lng, start_lat, end_lng, end_lat, type_member, rideable_type) %>%
    summarise(total = n(),.groups="drop") %>%
    arrange (desc(total)) %>% 
    filter(type_member == "member")
  
coordinates_table_member_200 <- coordinates_table_member[1:200, ]
  
# Lets join both table
  
coordinates_table_join_400 <- bind_rows(coordinates_table_casual_200, coordinates_table_member_200)
  
# Exporting the table to use it on Tableu 
  
write.table(coordinates_table_join_400, file="coordinates_table_join_400.csv", sep=",")

# lets visualize or maps

map <- readPNG("C:/Users/nacho/OneDrive/Documentos/R docs/09.2020_09.2022 Data Cyclistic, Case of Study/Dashboard.png", native=TRUE)
inset_element(map) <- ggp

getwd()

knitr::include_graphics("dashboard.png", error=FALSE)


# (3)

# share with conclusions

