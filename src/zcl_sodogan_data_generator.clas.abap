CLASS zcl_sodogan_data_generator DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    TYPES: tt_atrav TYPE STANDARD TABLE OF zrap_atrav_1507 WITH EMPTY KEY.
    INTERFACES if_oo_adt_classrun .
  PROTECTED SECTION.
  PRIVATE SECTION.
    METHODS:_clear_tables.
    METHODS: _load_travel_data RETURNING VALUE(count) TYPE sy-dbcnt.
    METHODS: _load_booking_data RETURNING VALUE(count) TYPE sy-dbcnt.
    METHODS: test EXPORTING er_data TYPE REF TO data.
ENDCLASS.



CLASS zcl_sodogan_data_generator IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.

    DATA: lt_atrav TYPE tt_atrav.
    DATA(guid_16) = cl_system_uuid=>create_uuid_x16_static(  ).

    test( IMPORTING er_data = DATA(lr_data)   ).

    out->write( lr_data->* ).

*Steps:
    _clear_tables(  ).
    _load_travel_data(  ).
    _load_booking_data(  ).

    out->write( |{ sy-dbcnt } number of records loaded into zrap_atrav_1507 | ).

  ENDMETHOD.
  METHOD _clear_tables.
    DELETE FROM zrap_atrav_1507.
    DELETE FROM zrap_abook_1507.

  ENDMETHOD.

  METHOD _load_travel_data.
    DATA: lt_atrav TYPE tt_atrav.
* select from the /dmo/travel
    SELECT  FROM /dmo/travel
            FIELDS
             uuid(  )      AS travel_uuid           ,
             travel_id     AS travel_id             ,
             agency_id     AS agency_id             ,
             customer_id   AS customer_id           ,
             begin_date    AS begin_date            ,
             end_date      AS end_date              ,
             booking_fee   AS booking_fee           ,
             total_price   AS total_price           ,
             currency_code AS currency_code         ,
             description   AS description           ,
             CASE status
               WHEN 'B' THEN 'A' " accepted
               WHEN 'X' THEN 'X' " cancelled
               ELSE 'O'          " open
             END           AS overall_status        ,
             createdby     AS created_by            ,
             createdat     AS created_at            ,
             lastchangedby AS last_changed_by       ,
             lastchangedat AS last_changed_at       ,
             lastchangedat AS local_last_changed_at
              ORDER BY travel_id ASCENDING
             INTO TABLE @DATA(lt_travel)
         .

    IF sy-subrc <> 0.
      SELECT   uuid(  )      AS travel_uuid           ,
               travel_id     AS travel_id             ,
               agency_id     AS agency_id             ,
               customer_id   AS customer_id           ,
               begin_date    AS begin_date            ,
               end_date      AS end_date              ,
               booking_fee   AS booking_fee           ,
               total_price   AS total_price           ,
               currency_code AS currency_code         ,
               description   AS description           ,
               CASE status
                 WHEN 'B' THEN 'A' " accepted
                 WHEN 'X' THEN 'X' " cancelled
                 ELSE 'O'          " open
               END           AS overall_status        ,
               createdby     AS created_by            ,
               createdat     AS created_at            ,
               lastchangedby AS last_changed_by       ,
               lastchangedat AS last_changed_at       ,
               lastchangedat AS local_last_changed_at
               FROM /dmo/travel
                ORDER BY travel_id ASCENDING
               INTO TABLE @lt_travel

           .
    ENDIF.

**One way to copy the data!
    lt_atrav =  CORRESPONDING #( lt_travel ).
    INSERT  zrap_atrav_1507 FROM TABLE @lt_atrav.
    COMMIT WORK.
    count = sy-dbcnt.
  ENDMETHOD.

  METHOD _load_booking_data.
    " insert booking demo data
    INSERT zrap_abook_1507 FROM (
        SELECT
          FROM   /dmo/booking    AS booking
            JOIN zrap_atrav_1507 AS z
            ON   booking~travel_id = z~travel_id
          FIELDS
            uuid( )                 AS booking_uuid          ,
            z~travel_uuid           AS travel_uuid           ,
            booking~booking_id      AS booking_id            ,
            booking~booking_date    AS booking_date          ,
            booking~customer_id     AS customer_id           ,
            booking~carrier_id      AS carrier_id            ,
            booking~connection_id   AS connection_id         ,
            booking~flight_date     AS flight_date           ,
            booking~flight_price    AS flight_price          ,
            booking~currency_code   AS currency_code         ,
            z~created_by            AS created_by            ,
            z~last_changed_by       AS last_changed_by       ,
            z~last_changed_at       AS local_last_changed_by
      ).
    COMMIT WORK.
  ENDMETHOD.

  METHOD test.
    TYPES:tt_travel TYPE STANDARD TABLE OF zi_rap_travel_1507 WITH EMPTY KEY.
    DATA: lt_travel TYPE tt_travel.

    SELECT * FROM zi_rap_travel_1507
                 INTO TABLE @lt_travel
             .

*    CREATE DATA er_data TYPE tt_travel.
     er_data = new tt_travel(  ).
     er_data->* = lt_travel.
*    ASSIGN er_data->* TO FIELD-SYMBOL(<lfs_travel>).
*    <lfs_travel> = lt_travel.


  ENDMETHOD.

ENDCLASS.
