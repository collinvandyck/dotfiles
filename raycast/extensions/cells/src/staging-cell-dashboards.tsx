import { DashboardList } from "./dashboard-list";
import { STAGING } from "./dashboards";
import { LAST_STAGING_CELL } from "./storage";

export default function Command() {
  return <DashboardList profile={STAGING} store={LAST_STAGING_CELL} />;
}
