// ============================================================
// Page 60016 — Late Open Order Lines Part  (FactBox)
// App    : Custom Dashboards
// Publisher: Frederico Torres
// ============================================================
// Embedded in LOG OTD Drill-Down as a FactBox.
// Shows open Sales Order Lines (AE*/AA*) with Outstanding Qty > 0
// and Requested Delivery Date IN [StartDate .. MIN(EndDate, Yesterday)].
// These are the same "Late" lines that feed into the OTD % denominator.
// ============================================================

page 60016 "LOG Late Open Order Lines Part"
{
    PageType        = ListPart;
    Caption         = 'Late Open Sales Order Lines';
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
        CustomerName: Text[100];

    // Called by LOG OTD Drill-Down on page open.
    // Mirrors CountLateOpenOrderLinesForOTD in the codeunit:
    // caps upper bound to yesterday so only Late lines are shown.
    procedure SetLateFilter(StartDate: Date; EndDate: Date)
    var
        LateEndDate: Date;
    begin
        LateEndDate := CalcDate('<-1D>', Today());
        if EndDate < LateEndDate then
            LateEndDate := EndDate;

        Rec.Reset();
        Rec.SetRange("Document Type", Rec."Document Type"::Order);
        Rec.SetFilter(Type, '%1', Rec.Type::Item);
        Rec.SetFilter("No.", 'AE*|AA*');
        Rec.SetFilter("Outstanding Quantity", '>0');

        // Line No. is always > 0; setting = 0 produces an empty result
        // for the edge case where the full period is still in the future.
        if LateEndDate < StartDate then
            Rec.SetRange("Line No.", 0)
        else
            Rec.SetFilter("Requested Delivery Date", '%1..%2', StartDate, LateEndDate);

        CurrPage.Update(false);
    end;

    trigger OnAfterGetRecord()
    var
        Customer: Record Customer;
    begin
        if Customer.Get(Rec."Sell-to Customer No.") then
            CustomerName := Customer.Name
        else
            CustomerName := '';
    end;
}
