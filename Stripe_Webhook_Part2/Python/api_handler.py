# api_handler.py
## webhook_events handler is called on every Stripe-Event request

import stripe
from django.http import HttpResponse
import datetime, json, psycopg2
import setup, utilities

stripe.api_key = setup.stripe_api_key
db_conn = setup.db_conn


def webhook_events(request, context):

    try:
    	event_json = json.loads(request.body)

    	if valid_event(event_json):
        	utilities.store_response_in_db(event_json, db_conn)
        	return HttpResponse(status=200)

    except Exception as e:
        print("Bad Request")
        return HttpResponse(status=400)



def valid_event(body):		# checks if the request object is a Stripe event 
	if event.get('object') == "event":
		return True
	raise ValueError("Not an Event Request")
