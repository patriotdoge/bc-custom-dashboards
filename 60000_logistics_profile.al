// ============================================================
// Profile — LOGISTICS  (Logistics Manager)
// App    : Custom Dashboards
// Publisher: Frederico Torres
// ============================================================
// Assigns Page 60000 "LOG Logistics Role Center" as the
// default landing page for users with this profile.
//
// To assign a user:
//   Settings → Users → [select user] → Profile = LOGISTICS
// ============================================================

profile "LOGISTICS"
{
    Caption = 'Logistics Manager';
    ProfileDescription = 'Logistics landing page with live KPIs.';
    RoleCenter = "LOG Logistics Role Center";
    Enabled = true;
    Promoted = true;
}
