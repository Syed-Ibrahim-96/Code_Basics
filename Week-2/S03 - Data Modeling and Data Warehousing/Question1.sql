USE VayuAir;

SELECT * FROM bronze_bookings;

SELECT * FROM bronze_flights;

/*
1. Grain
-- Grain: One row represents one passenger booking for a specific flight (one booking_id).


2. Column classification
|-------------------------------------------------------------------------- |
|	    Source		|	    Column		    |	   Classification			|
|-------------------------------------------------------------------------- |
|	bronze_bookings	|	booking_id			|	Degenerate dimension key	|	
|	bronze_bookings	| 	passenger_id		|	Dimension key				|
|	bronze_bookings	|	flight_id			|	Dimension key				|
|	bronze_bookings	|	booking_date		|	Date dimension key			|
|	bronze_bookings	|	travel_date			|	Date dimension key			|
|	bronze_bookings	|	fare_class			|	Dimension attribute			|
|	bronze_bookings	|	booking_status		|	Dimension attribute			|
|	bronze_flights	|	flight_number		|	Dimension attribute			|
|	bronze_flights	|	origin_airport_code	|	Dimension attribute			|
|	bronze_flights	|	dest_airport_code	|	Dimension attribute			|
|	bronze_flights	|	aircraft_code		|	Dimension attribute			|
|	bronze_flights	|	flight_date	Date	|	dimension key				|
|-------------------|-----------------------|-------------------------------|

* Degenerate dimension key --> A degenerate dimension is a dimension identifier that exists directly in the fact table without having a separate dimension table.

* Dimension key --> A dimension key is a key used to connect a fact table to a dimension table.
					Usually, in a dimensional model, we use a surrogate key as the primary key of a dimension table.

* Date dimension key --> A date dimension key connects the fact table to a date dimension.

* Dimension attribute --> A dimension attribute is a descriptive column that provides additional information about a dimension.

Measures
Source	Column	Classification
bronze_bookings	fare_amount	Measure
bronze_bookings	tax_amount	Measure
bronze_bookings	miles_earned	Measure

3. Additive vs. non-additive
Additive --> fare_amount, tax_amount, and miles_earned are additive measures that can be summed across bookings. 

non-additive --> Average fare is an example of a non-additive value because averages should be recalculated rather than summed.

*/