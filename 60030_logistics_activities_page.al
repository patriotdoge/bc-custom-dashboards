// ============================================================
// Page 60030 — Logistics Activities  (CardPart / Cue page)
// App    : Custom Dashboards
// Publisher: Frederico Torres
// ============================================================
// Embedded cue part in the Role Center showing daily
// operational metrics: pending shipments and overdue lines.
// Both tiles support drill-down to the underlying records.
// ============================================================

page 60030 "LOG Logistics Activities"
{
    PageType          = CardPart;
    Caption           = 'Logistics Activities';
    RefreshOnActivate = true;
    ApplicationArea   = All;

    layout
    {
        area(Content)
        {
            cuegroup(ShipmentCues)
            {
                Caption = 'Shipments';

                field(PendingShipmentsCue; PendingShipments)
                {
                    ApplicationArea = All;
                    Caption         = 'Pending Shipments';
                    ToolTip         = 'Released sales orders ready to ship (not yet posted).';
                    DrillDown       = true;

                    trigger OnDrillDown()
                    var
                        SalesHeader: Record "Sales Header";
                    begin
                        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
                        SalesHeader.SetRange(Status, SalesHeader.Status::Released);
                        Page.Run(0, SalesHeader);
                    end;
                }

                field(OverdueDeliveriesCue; OverdueDeliveries)
                {
                    ApplicationArea = All;
                    Caption         = 'Overdue Deliveries';
                    ToolTip         = 'Open order lines with requested delivery date before today and outstanding quantity > 0.';
                    StyleExpr       = OverdueStyle;
                    DrillDown       = true;

                    trigger OnDrillDown()
                    var
                        SalesLine: Record "Sales Line";
                    begin
                        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
                        SalesLine.SetFilter("Requested Delivery Date", '<%1', Today());
                        SalesLine.SetFilter("Outstanding Quantity", '>0');
                        Page.Run(0, SalesLine);
                    end;
                }
            }
        }
    }

    var
        PendingShipments: Integer;
        OverdueDeliveries: Integer;
        OverdueStyle: Text;

    trigger OnOpenPage()
    begin
        CalculateActivities();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        CalculateActivities();
    end;

    local procedure CalculateActivities()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.SetRange(Status, SalesHeader.Status::Released);
        PendingShipments := SalesHeader.Count();

        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetFilter("Requested Delivery Date", '<%1', Today());
        SalesLine.SetFilter("Outstanding Quantity", '>0');
        OverdueDeliveries := SalesLine.Count();

        if OverdueDeliveries > 0 then
            OverdueStyle := 'Unfavorable'
        else
            OverdueStyle := 'Favorable';
    end;
}
