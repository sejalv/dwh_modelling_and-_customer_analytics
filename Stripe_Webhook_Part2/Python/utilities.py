# utilities.py
## this module is for all the functions that parse the JSON response, and retrieve from and insert details into Postgres tables.

def store_response_in_db(event, db_conn):
    
        if event.get('type'):
        	event_type = event.get('type').split('.')

        	if len(event_type) > 1:
        		if event_type[0] == 'charge':

        			if event_type[1] == 'succeeded':

        				# this block of code can be made into a function, once actions for other event_types are understood.
        				try:
	        				source = event.get('data').get('object').get('source')
	        				data_object = event.get('data').get('object')

							conn = psycopg2.connect(db_conn)
		
							# retrieve associated user_ID from Users table, if exists
	        				user = get_user(conn, source.get('customer'))
	        				print("Found User: {}".format(source.get('customer')))

	        				if not user:	# if user does not exist
	        					set_user(conn, source)
	        					print("Created User: {}".format(source.get('customer')))

	        				# retrieve last entered details for user
	        				user = get_user(conn, source.get('customer'))
	        				print("Found User: {}".format(source.get('customer')))

	        				# retrieve the associated uspm_ID from User_Saved_Payment_Modes table, if exists
							uspm = get_uspm(conn, source, user['user_id'])
							print("Found uspm_ID for user: {}".format(source.get('customer')))
		
							if not uspm:	# if payment/card does not exist
								set_uspm(conn, source, user['user_id'])
								print("Created uspm_id for user: {}".format(source.get('customer')))

							# retrieve last entered details for uspm
							uspm = get_uspm(conn, source, user['user_id'])
							print("Found uspm_ID for user: {}".format(source.get('customer')))

	        				# Enter new transaction detail
	        				set_transaction(conn, data_object.get('created'), uspm['uspm_id'], event_type[0], data_object.get('amount'), data_object.get('currency'))
	        				print("Transaction detail creeated for user: {}".format(source.get('customer')))

	        			except:
	        				raise ValueError("DB Exception occurred")


        			if event_type[1] == 'failed':
        				# do stuff
        				pass

        			# .............................. #
        			# .. code for other sub-types .. #
        			# .............................. #


        		if event_type[0] == 'account':
        			# do stuff
        			pass

				# .......................... #
        		# .. code for other types .. #
        		# .......................... #


        	if event_type[0] == 'ping':
        		# do stuff
        		pass



def get_user(conn, response_user_id):
	# check if payment/card entry is saved for the customer in User_Saved_Payment_Modes table

	cursor = conn.cursor()
	cursor.execute("""SELECT * FROM Users WHERE cust_id = {};""").format(response_user_id)

	rows = cursor.fetchall()
	return rows


def set_user(conn, source):
	# Save new payment/card entry

	cursor = conn.cursor()
	cursor.execute("""INSERT INTO Users 
		(cust_id, country_code, address_line1, address_line2, address_city, address_state, address_zip)
		VALUES({},{},{},{},{},{},{},{});
		""").format(int(source.get('customer')), source.get('country'), source.get('address_line1'), source.get('address_line2')
			,source.get('address_city') ,source.get('address_state'), int(source.get('address_zip')))
	cursor.commit()



def get_uspm(conn, source, user_id):
	# check if payment/card entry is saved for the customer in User_Saved_Payment_Modes table

	cursor = conn.cursor()
	cursor.execute("""SELECT * FROM User_Saved_Payment_Modes 
						WHERE user_id = {} AND payment_encrypted_id = {} AND payment_type = {} AND card_num_last_4_digits = {} AND card_type = {}
						AND card_exp_month = {} AND card_exp_year = {};
						""").format(int(user_id), source.get('id'), source.get('object'), source.get('last4'), source.get('type')
							,source.get('exp_month') ,source.get('exp_year'))

	rows = cursor.fetchall()
	return rows


def set_uspm(conn, source, user_id):
	# Save new payment/card entry

	cursor = conn.cursor()
	cursor.execute("""INSERT INTO User_Saved_Payment_Modes 
		(user_id, payment_encrypted_id, payment_type, card_num_last_4_digits, card_type, card_exp_month, card_exp_year, card_brand)
		VALUES({},{},{},{},{},{},{},{});
		""").format(int(user_id), source.get('id'), source.get('object'), int(source.get('last4')), source.get('type')
			,int(source.get('exp_month')) ,int(source.get('exp_year')), source.get('brand'))

	cursor.commit()



def set_transaction(conn, created_epoch, uspm_id, transaction_type, amount, currency):
	# Insert a new transaction into Transactions_Fact table

	cursor = conn.cursor()

	# epoch to UTC
	ts = datetime.datetime.utcfromtimestamp(created_epoch)
	
	cursor.execute("""INSERT INTO Transactions_Fact (uspm_id, transaction_ts, transaction_type, amount, currency)
						VALUES ({}, {});""").format(int(uspm_id), ts, transaction_type, float(amount), currency)

	cursor.commit()
