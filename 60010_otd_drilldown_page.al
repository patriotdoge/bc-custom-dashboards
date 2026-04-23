// ============================================================
// Page 60010 — OTD Drill-Down
// App    : Custom Dashboards
// Publisher: Frederico Torres
// ============================================================
// Shows Posted Sales Shipment Lines used in the R001
// calculation with an on-time flag (Yes / No — Late)
// coloured green/red via StyleExpr.
// ============================================================

page 60010 "LOG OTD Drill-Down"
{
    PageType        = List;
    Caption         = 'OTD — Shipment Line Detail';
    SourceTable     = "Sales Shipment Line";
    Editable        = false;
    UsageCategory   = None;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = All;
                    Caption         = 'Shipment No.';
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    Caption         = 'Item No.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field("Shipment Date"; Rec."Shipment Date")
                {
                    ApplicationArea = All;
                }
                field("Requested Delivery Date"; Rec."Requested Delivery Date")
                {
                    ApplicationArea = All;
                }
                field(OnTimeFlag; GetOnTimeLabel(Rec."Shipment Date", Rec."Requested Delivery Date"))
                {
                    ApplicationArea = All;
                    Caption         = 'On Time?';
                    StyleExpr       = OnTimeFlagStyle;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = All;
                }
                field("Sell-to Customer No."; Rec."Sell-to Customer No.")
                {
                    ApplicationArea = All;
                    Caption         = 'Customer No.';
                }
                field(CustomerNameField; CustomerName)
                {
                    ApplicationArea = All;
                    Caption         = 'Customer Name';
                }
            }
        }
    }

    var
        OnTimeFlagStyle: Text;
        CustomerName: Text[100];

    trigger OnOpenPage()
    begin
        Rec.SetFilter("No.", 'AE*|AA*');
        Rec.SetFilter(Type, '%1', Rec.Type::Item);
    end;

    trigger OnAfterGetRecord()
    var
        Customer: Record Customer;
    begin
        if (Rec."Shipment Date" = 0D) or (Rec."Requested Delivery Date" = 0D) then
            OnTimeFlagStyle := ''
        else if Rec."Shipment Date" <= Rec."Requested Delivery Date" then
            OnTimeFlagStyle := 'Favorable'
        else
            OnTimeFlagStyle := 'Unfavorable';

        if Customer.Get(Rec."Sell-to Customer No.") then
            CustomerName := Customer.Name
        else
            CustomerName := '';
    end;

    local procedure GetOnTimeLabel(ShipDate: Date; ReqDate: Date): Text
    begin
        if (ShipDate = 0D) or (ReqDate = 0D) then
            exit('—');
        if ShipDate <= ReqDate then
            exit('Yes')
        else
            exit('No — Late');
    end;
}
