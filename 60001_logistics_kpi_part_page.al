// ============================================================
// Page 60001 — Logistics KPI Part  (CardPart embedded in RC)
// App    : Custom Dashboards
// Publisher: Frederico Torres
// ============================================================
// CardPart embedded in "LOG Logistics Role Center".
// Owns the date-filter inputs, KPI cue tiles, and the
// Recalculate / This Month / This Year actions.
// ============================================================

page 60001 "LOG Logistics KPI Part"
{
    PageType          = CardPart;
    Caption           = 'Logistics KPIs';
    RefreshOnActivate = true;
    ApplicationArea   = All;

    layout
    {
        area(Content)
        {
            // ── Analysis period ──────────────────────────────
            group(DateFilterGroup)
            {
                Caption     = 'Analysis Period';
                ShowCaption = true;

                field(StartDateField; StartDate)
                {
                    ApplicationArea = All;
                    Caption         = 'From';
                    ToolTip         = 'Start of the KPI calculation period.';

                    trigger OnValidate()
                    begin
                        RefreshKPIs();
                    end;
                }
                field(EndDateField; EndDate)
                {
                    ApplicationArea = All;
                    Caption         = 'To';
                    ToolTip         = 'End of the KPI calculation period.';

                    trigger OnValidate()
                    begin
                        RefreshKPIs();
                    end;
                }
                field(LastCalcField; KPIBuffer."Last Calculated At")
                {
                    ApplicationArea = All;
                    Caption         = 'Last updated';
                    Editable        = false;
                    ToolTip         = 'Date and time the KPIs were last recalculated.';
                }
            }

            // ── KPI Cue tiles ────────────────────────────────
            cuegroup(KPICues)
            {
                Caption     = 'Logistics KPIs';
                ShowCaption = true;

                // R001 — OTD %
                field(OTDCue; KPIBuffer."OTD Pct")
                {
                    ApplicationArea = All;
                    Caption         = 'On-Time Delivery (%)';
                    ToolTip         = 'Ratio of shipment lines delivered on or before the requested delivery date over total expected lines (shipped + open) in the selected period. Items: AE* and AA*.';
                    DrillDown       = true;

                    trigger OnDrillDown()
                    begin
                        Page.Run(Page::"LOG OTD Drill-Down");
                    end;
                }

                // R002 — Avg Storage Time
                field(AvgStorageCue; KPIBuffer."Avg Storage Days")
                {
                    ApplicationArea = All;
                    Caption         = 'Avg. Storage Time (days)';
                    ToolTip         = 'Average days products remain in stock before shipment. Formula: Period Days / (COGS / Avg Stock Value). Locations: STOCK, QR, NC, FR*. Excludes SA* and Refurbished items.';
                    DrillDown       = true;

                    trigger OnDrillDown()
                    begin
                        Page.Run(Page::"LOG Storage Drill-Down");
                    end;
                }

                // Supporting — on-time line count
                field(OnTimeLinesField; KPIBuffer."OTD On-Time Lines")
                {
                    ApplicationArea = All;
                    Caption         = 'On-Time Lines';
                    ToolTip         = 'Shipment lines delivered on or before the requested date.';
                    DrillDown       = true;

                    trigger OnDrillDown()
                    begin
                        Page.Run(Page::"LOG OTD Drill-Down");
                    end;
                }

                // Supporting — open/late line count
                field(OpenLateLinesField; KPIBuffer."OTD Open Late Lines")
                {
                    ApplicationArea = All;
                    Caption         = 'Open / Late Lines';
                    ToolTip         = 'Open order lines with outstanding quantity and requested delivery date within the selected period.';
                    StyleExpr       = OpenLateStyle;
                    DrillDown       = true;

                    trigger OnDrillDown()
                    begin
                        Page.Run(Page::"LOG OTD Drill-Down");
                    end;
                }

                // Supporting — inventory turnover
                field(TurnoverField; KPIBuffer."Inventory Turnover Rate Pct")
                {
                    ApplicationArea = All;
                    Caption         = 'Inventory Turnover (%)';
                    ToolTip         = 'COGS divided by average stock value, as a percentage.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RecalcAction)
            {
                ApplicationArea = All;
                Caption         = 'Recalculate KPIs';
                Image           = Refresh;
                ToolTip         = 'Force recalculation of both KPIs for the selected period.';

                trigger OnAction()
                begin
                    RefreshKPIs();
                    Message(KPIsRefreshedMsg, StartDate, EndDate);
                end;
            }
            action(SetCurrentMonth)
            {
                ApplicationArea = All;
                Caption         = 'This Month';
                Image           = Period;
                ToolTip         = 'Set the date filter to the current calendar month.';

                trigger OnAction()
                begin
                    StartDate := CalcDate('<-CM>', Today());
                    EndDate   := CalcDate('<CM>', Today());
                    RefreshKPIs();
                end;
            }
            action(SetCurrentYear)
            {
                ApplicationArea = All;
                Caption         = 'This Year';
                Image           = Period;
                ToolTip         = 'Set the date filter to the current calendar year.';

                trigger OnAction()
                begin
                    StartDate := DMY2Date(1, 1, Date2DMY(Today(), 3));
                    EndDate   := DMY2Date(31, 12, Date2DMY(Today(), 3));
                    RefreshKPIs();
                end;
            }
        }
    }

    var
        KPIBuffer: Record "LOG Logistics KPI Buffer" temporary;
        StartDate: Date;
        EndDate: Date;
        OpenLateStyle: Text;
        KPIsRefreshedMsg: Label 'KPIs recalculated for %1 to %2.', Comment = '%1=Start Date,%2=End Date';

    trigger OnOpenPage()
    begin
        StartDate := CalcDate('<-CM>', Today());
        EndDate   := Today();
        RefreshKPIs();
    end;

    local procedure RefreshKPIs()
    begin
        if (StartDate = 0D) or (EndDate = 0D) or (StartDate > EndDate) then
            exit;

        KPIBuffer.Refresh(StartDate, EndDate);
        KPIBuffer.Get('KPI');

        if KPIBuffer."OTD Open Late Lines" > 0 then
            OpenLateStyle := 'Unfavorable'
        else
            OpenLateStyle := 'Favorable';

        CurrPage.Update(false);
    end;
}
