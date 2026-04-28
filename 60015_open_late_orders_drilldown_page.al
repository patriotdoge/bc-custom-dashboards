// ============================================================
// Page 60015 — Open / Late Sales Order Lines Drill-Down
// App    : Custom Dashboards
// Publisher: Frederico Torres
// ============================================================
// Shows open Sales Order Lines for AE*/AA* items with
// Requested Delivery Date within the selected period and
// Outstanding Quantity > 0.
//
// Line Status:
//   Late  — Requested Delivery Date < Today  → red
//   Open  — Requested Delivery Date ≥ Today  → amber
// ============================================================

page 60015 "LOG Open Late Order Lines"
{
    PageType        = List;
    Caption         = 'Open / Late Sales Order Lines';
    SourceTable     = "Sales Line";
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
                    Caption         = 'Order No.';
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
                field("Requested Delivery Date"; Rec."Requested Delivery Date")
                {
                    ApplicationArea = All;
                }
                field("Outstanding Quantity"; Rec."Outstanding Quantity")
                {
                    ApplicationArea = All;
                }
                field(LineStatus; GetLineStatus(Rec."Requested Delivery Date"))
                {
                    ApplicationArea = All;
                    Caption         = 'Line Status';
                    StyleExpr       = LineStatusStyle;
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
        LineStatusStyle: Text;
        CustomerName: Text[100];

    trigger OnOpenPage()
    begin
        Rec.SetCurrentKey("Requested Delivery Date");
        Rec.Ascending(false);
    end;

    procedure SetDateFilter(StartDate: Date; EndDate: Date)
    begin
        Rec.SetRange("Document Type", Rec."Document Type"::Order);
        Rec.SetFilter(Type, '%1', Rec.Type::Item);
        Rec.SetFilter("No.", 'AE*|AA*');
        Rec.SetFilter("Outstanding Quantity", '>0');
        Rec.SetFilter("Requested Delivery Date", '%1..%2', StartDate, EndDate);
    end;

    trigger OnAfterGetRecord()
    var
        Customer: Record Customer;
    begin
        if Rec."Requested Delivery Date" < Today() then
            LineStatusStyle := 'Unfavorable'
        else
            LineStatusStyle := 'Ambiguous';

        if Customer.Get(Rec."Sell-to Customer No.") then
            CustomerName := Customer.Name
        else
            CustomerName := '';
    end;

    local procedure GetLineStatus(ReqDate: Date): Text
    begin
        if ReqDate < Today() then
            exit('Late')
        else
            exit('Open');
    end;
}
