#Inicio de servidor entre semana
0 19 * * 1,2,3,4,5 /home/pi/Script/ec2/start_instance.sh

#Apagado de servidor entre semana
0 23 * * 1,2,3,4,5 /home/pi/Script/ec2/stop_instance.sh

#Inicio de servirdor Sabado
0 9 * * 6 /home/pi/Script/ec2/start_instance.sh
0 2 * * 0 /home/pi/Script/ec2/stop_instance.sh

#Inicio de servidor en Domingo
0 9 * * 0 /home/pi/Script/ec2/start_instance.sh
0 23 * * 0 /home/pi/Script/ec2/stop_instance.sh
