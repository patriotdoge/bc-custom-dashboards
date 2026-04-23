// ============================================================
// Codeunit 60000 — R001 Customer On-Time Delivery (OTD)
// App    : Custom Dashboards
// Publisher: Frederico Torres
// ============================================================
// Formula:
//   OTD% = OnTimeLines / (OnTimeLines + OpenLateLines) × 100
//
// OnTimeLines  : Posted Sales Shipment Lines where
//                  No. filter = AE*|AA*
//                  Requested Delivery Date IN [StartDate..EndDate]
//                  Shipment Date <= Requested Delivery Date
//
// OpenLateLines: Sales Lines (Document Type = Order) where
//                  No. filter = AE*|AA*
//                  Requested Delivery Date IN [StartDate..EndDate]
//                  Outstanding Quantity > 0
// ============================================================

codeunit 60000 "LOG OTD Calculation"
{
    procedure CalcOTD(StartDate: Date; EndDate: Date): Decimal
    var
        OnTimeLines: Integer;
        OpenLateLines: Integer;
        TotalLines: Integer;
        OTDPct: Decimal;
    begin
        OnTimeLines   := CountOnTimeShipmentLines(StartDate, EndDate);
        OpenLateLines := CountOpenLateOrderLines(StartDate, EndDate);
        TotalLines    := OnTimeLines + OpenLateLines;

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
    // Convenience: return both numerator and denominator
    // for drill-down / detail pages
    // ----------------------------------------------------------
    procedure GetOTDBreakdown(StartDate: Date; EndDate: Date;
                               var OnTime: Integer; var OpenLate: Integer)
    begin
        OnTime   := CountOnTimeShipmentLines(StartDate, EndDate);
        OpenLate := CountOpenLateOrderLines(StartDate, EndDate);
    end;
}
