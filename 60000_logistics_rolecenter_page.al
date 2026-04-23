// ============================================================
// Page 60000 — Logistics Role Center  (Landing Page)
// App    : Custom Dashboards
// Publisher: Frederico Torres
// ============================================================
// PageType = RoleCenter — assigned to the LOGISTICS profile.
//
// A RoleCenter page may only contain part() elements in its
// layout; no fields, cuegroups, triggers, or procedures are
// allowed here. All KPI logic lives in the embedded parts.
//
// Layout:
//   [KPI Part]        — date filter + OTD & Avg Storage tiles
//                       (Page 60001 "LOG Logistics KPI Part")
//   [Activities part] — pending shipments / overdue cues
//                       (Page 60030 "LOG Logistics Activities")
// ============================================================

page 60000 "LOG Logistics Role Center"
{
    PageType        = RoleCenter;
    Caption         = 'Logistics';
    ApplicationArea = All;

    layout
    {
        area(RoleCenter)
        {
            part(KPIPart; "LOG Logistics KPI Part")
            {
                ApplicationArea = All;
            }
            part(ActivitiesPart; "LOG Logistics Activities")
            {
                ApplicationArea = All;
            }
        }
    }
}
