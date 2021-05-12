# Fitness
Shows progress of several fitness goals, such as weight loss, calorie deficits, and weightlifting.

![Image](https://github.com/tmam101/Fitness/blob/main/Demo/Home%20screen%201.jpeg?raw=true)
![Image](https://github.com/tmam101/Fitness/blob/main/Demo/Home%20screen%202.jpeg?raw=true)

All data is pulled from HealthKit. Calories burned, both active and resting, are subtracted from calories eaten to determine the user's calorie deficit for the day. For example, if the user burns 2300 calories naturally during the day, and also exercises to burn 300 calories, they have burned 2600 calories for the day. If they then eat 2000 calories, they have a deficit of 600 for the day. The default deficit goal is 1000 calories. 

The orange ring shows the average deficit of all time.
The yellow ring shows the average deficit for the week.
The translucent yellow ring shows what the average weekly deficit will be tomorrow based on today's deficit. 
The blue ring shows today's deficit in relation to what it would need to be for tomorrow's average weekly deficit to meet the goal.

The bar graph shows the daily deficits for the past week. The blue bar on the right shows today's deficit. From right to left, it shows the deficits of the most recent 7 days. A yellow bar represents a deficit, and a red bar represents a surplus. The gray bar represents a value of 1000 calories. 
