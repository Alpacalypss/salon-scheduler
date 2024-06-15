#!/bin/bash

PSQL="psql -X --username=freecodecamp --dbname=salon --tuples-only -c"

echo -e "\n~~~~~ MY SALON ~~~~~\n"

MAIN_MENU(){
  #argument acceptance for menu selections
  if [[ $1 ]]
  then
    echo -e "\n$1"
  else
    echo -e "\nWelcome to My Salon, how can I help you?\n"
  fi

  #get list of services
  AVAILABLE_SERVICES=$($PSQL "SELECT * FROM services ORDER BY service_id")

  echo "$AVAILABLE_SERVICES" | while read SERVICE_ID BAR NAME
    do
      #format services
      echo -e "$SERVICE_ID) $NAME"
    done

  #ask which service they would like
  read SERVICE_ID_SELECTED
  #find service name
  SERVICE_NAME=$($PSQL "SELECT name FROM services WHERE service_id=$SERVICE_ID_SELECTED")
  #if input is not a correct
  if [[ -z $SERVICE_NAME ]]
  then
    #resend to menu
    MAIN_MENU "I could not find that service. What would you like today?"
  else
    MAKE_APPOINTMENT $SERVICE_ID_SELECTED $SERVICE_NAME
  fi
}

MAKE_APPOINTMENT() {
  SERVICE_ID=$1
  SERVICE_NAME=$2

  echo -e "\nWhat's your phone number?"
  #ask for phone number
  read CUSTOMER_PHONE
  #get customer info
  CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone='$CUSTOMER_PHONE'")
      
  #if customer phone exist ask for name
  if [[ -z $CUSTOMER_ID ]]
  then
    echo -e "\nI don't have a record for that phone number, what's your name?"
    #ask for name
    read CUSTOMER_NAME
    #insert new customer
    CUSTOMER_INSERT_RESULT=$($PSQL "INSERT INTO customers(name, phone) VALUES ('$CUSTOMER_NAME', '$CUSTOMER_PHONE')")
  fi

  CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE phone='$CUSTOMER_PHONE'") 
  #get customer id
  CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone='$CUSTOMER_PHONE'")
  
  #remove whitespace from service name
  SERVICE_NAME_FORMATTED=$(echo -e "$SERVICE_NAME" | sed -E 's/ *$|^ *//g')
  #remove whitespace from customer name
  CUSTOMER_NAME_FORMATTED=$(echo -e "$CUSTOMER_NAME" | sed -E 's/ *$|^ *//g')
  
  #ask what time for appointment
  echo -e "\nWhat time would you like your $SERVICE_NAME_FORMATTED, $CUSTOMER_NAME_FORMATTED?"     
  read SERVICE_TIME
  
  #validate service time
  if [[ ! $SERVICE_TIME =~ ^([0-9]{1,2}(:[0-9]{2})?\s*(AM|PM|am|pm)?)$ ]]
  then
    echo -e "Please enter a valid time"
    read SERVICE_TIME
  else
    SERVICE_TIME_FORMATTED=$(echo "$SERVICE_TIME" | sed -E 's/ *$|^ *//g')
    
    #insert appointment
    INSERT_APPOINTMENT_RESULT=$($PSQL "INSERT INTO appointments(customer_id, service_id, time) VALUES ('$CUSTOMER_ID', '$SERVICE_ID_SELECTED', '$SERVICE_TIME')")
    if [[ $INSERT_APPOINTMENT_RESULT == "INSERT 0 1" ]]
    then
      echo -e "I have put you down for a $SERVICE_NAME_FORMATTED at $SERVICE_TIME_FORMATTED, $CUSTOMER_NAME_FORMATTED."
    fi
  fi
}

MAIN_MENU
