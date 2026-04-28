// ============================================================
// Codeunit 60000 — R001 Customer On-Time Delivery (OTD)
// App    : Custom Dashboards
// Publisher: Frederico Torres
// ============================================================
// Formula:
//   OTD% = OnTimeLines / (OnTimeLines + LateShipmentLines + LateOpenLines) × 100
//
// OnTimeLines      : Posted Sales Shipment Lines where
//                      No. filter = AE*|AA*
//                      Requested Delivery Date IN [StartDate..EndDate]
//                      Shipment Date <= Requested Delivery Date
//
// LateShipmentLines: Posted Sales Shipment Lines where
//                      No. filter = AE*|AA*
//                      Requested Delivery Date IN [StartDate..EndDate]
//                      Shipment Date > Requested Delivery Date
//
// LateOpenLines    : Open Sales Order Lines where
//                      No. filter = AE*|AA*
//                      Requested Delivery Date IN [StartDate..MIN(EndDate, Yesterday)]
//                      Outstanding Quantity > 0
//                    (unshipped lines already past their delivery date = failures)
// ============================================================

codeunit 60000 "LOG OTD Calculation"
{
    procedure CalcOTD(StartDate: Date; EndDate: Date): Decimal
    var
        OnTimeLines: Integer;
        LateShipmentLines: Integer;
        LateOpenLines: Integer;
        TotalLines: Integer;
        OTDPct: Decimal;
    begin
        OnTimeLines       := CountOnTimeShipmentLines(StartDate, EndDate);
        LateShipmentLines := CountLateShipmentLines(StartDate, EndDate);
        LateOpenLines     := CountLateOpenOrderLinesForOTD(StartDate, EndDate);
        TotalLines        := OnTimeLines + LateShipmentLines + LateOpenLines;

        if TotalLines = 0 then
            exit(0);

        OTDPct := Round((OnTimeLines / TotalLines) * 100, 0.01);
        exit(OTDPct);
    end;

    // ----------------------------------------------------------
    // Steps 1+3: Posted Sales Shipment Lines
    //   Filter : No. = AE*|AA*
    //            Requested Delivery Date IN [StartDate..EndDate]
    //   On-time: Shipment Date <= Requested Delivery Date
    // ----------------------------------------------------------
    local procedure CountOnTimeShipmentLines(StartDate: Date; EndDate: Date): Integer
    var
        SalesShipLine: Record "Sales Shipment Line";
        Counter: Integer;
    begin
        Counter := 0;

        SalesShipLine.SetFilter("No.", 'AE*|AA*');
        SalesShipLine.SetFilter("Requested Delivery Date", '%1..%2', StartDate, EndDate);
        SalesShipLine.SetFilter(Type, '%1', SalesShipLine.Type::Item);

        if SalesShipLine.FindSet() then
            repeat
                if (SalesShipLine."Shipment Date" <> 0D) and
                   (SalesShipLine."Requested Delivery Date" <> 0D) and
                   (SalesShipLine."Shipment Date" <= SalesShipLine."Requested Delivery Date")
                then
                    Counter += 1;
            until SalesShipLine.Next() = 0;

        exit(Counter);
    end;

    // ----------------------------------------------------------
    // Steps 5+6+7: Open Sales Order Lines (not yet shipped)
    //   Filter : Document Type = Order
    //            No. = AE*|AA*
    //            Requested Delivery Date IN [StartDate..EndDate]
    //            Outstanding Quantity > 0
    // Used for the "Open / Late Sales Order Lines" cue tile (Open + Late).
    // ----------------------------------------------------------
    local procedure CountOpenLateOrderLines(StartDate: Date; EndDate: Date): Integer
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetFilter("No.", 'AE*|AA*');
        SalesLine.SetFilter("Requested Delivery Date", '%1..%2', StartDate, EndDate);
        SalesLine.SetFilter("Outstanding Quantity", '>0');
        SalesLine.SetFilter(Type, '%1', SalesLine.Type::Item);

        exit(SalesLine.Count());
    end;

    // ----------------------------------------------------------
    // Late-only open order lines: same as above but capped at
    // yesterday so only lines past their delivery date are counted.
    // These are treated as OTD failures in the percentage formula.
    // ----------------------------------------------------------
    local procedure CountLateOpenOrderLinesForOTD(StartDate: Date; EndDate: Date): Integer
    var
        SalesLine: Record "Sales Line";
        LateEndDate: Date;
    begin
        LateEndDate := CalcDate('<-1D>', Today());
        if LateEndDate < StartDate then
            exit(0);
        if EndDate < LateEndDate then
            LateEndDate := EndDate;

        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetFilter("No.", 'AE*|AA*');
        SalesLine.SetFilter("Requested Delivery Date", '%1..%2', StartDate, LateEndDate);
        SalesLine.SetFilter("Outstanding Quantity", '>0');
        SalesLine.SetFilter(Type, '%1', SalesLine.Type::Item);

        exit(SalesLine.Count());
    end;

    // ----------------------------------------------------------
    // Steps 1+3 (late): Posted Shipment Lines where
    //   Shipment Date > Requested Delivery Date
    // ----------------------------------------------------------
    local procedure CountLateShipmentLines(StartDate: Date; EndDate: Date): Integer
    var
        SalesShipLine: Record "Sales Shipment Line";
        Counter: Integer;
    begin
        Counter := 0;

        SalesShipLine.SetFilter("No.", 'AE*|AA*');
        SalesShipLine.SetFilter("Requested Delivery Date", '%1..%2', StartDate, EndDate);
        SalesShipLine.SetFilter(Type, '%1', SalesShipLine.Type::Item);

        if SalesShipLine.FindSet() then
            repeat
                if (SalesShipLine."Shipment Date" <> 0D) and
                   (SalesShipLine."Requested Delivery Date" <> 0D) and
                   (SalesShipLine."Shipment Date" > SalesShipLine."Requested Delivery Date")
                then
                    Counter += 1;
            until SalesShipLine.Next() = 0;

        exit(Counter);
    end;

    // ----------------------------------------------------------
    // Convenience: return all four counts for buffer + drill-down.
    // LateOpenForOTD = late open order lines only (< Today),
    // included in the OTD % denominator as unshipped failures.
    // ----------------------------------------------------------
    procedure GetOTDBreakdown(StartDate: Date; EndDate: Date;
                               var OnTime: Integer; var OpenLate: Integer;
                               var LateShipped: Integer; var LateOpenForOTD: Integer)
    begin
        OnTime         := CountOnTimeShipmentLines(StartDate, EndDate);
        OpenLate       := CountOpenLateOrderLines(StartDate, EndDate);
        LateShipped    := CountLateShipmentLines(StartDate, EndDate);
        LateOpenForOTD := CountLateOpenOrderLinesForOTD(StartDate, EndDate);
    end;
}
