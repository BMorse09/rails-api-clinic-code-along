# index

# show

# create


   curl --include --request POST http://localhost:3000/patients \
     --header "Content-Type: application/json" \
     --data '{
       "patient": {
         "name": "Will",
         "sickness": "Runs too fast"
       }
     }'

     curl --include --request PATCH http://localhost:3000/patients/2 \
       --header "Content-Type: application/json" \
       --data '{
         "patient": {
           "name": "Will McBride",
           "sickness": "Runs too fast"
         }
       }'

       curl --include --request DELETE http://localhost:3000/patients/2 \
         --header "Content-Type: application/json"
         --data '{
           "patient": {
             "name": "Will McBride",
             "sickness": "Runs too fast"
           }
         }'
