import { DashboardList } from "./dashboard-list";
import { PROD } from "./dashboards";
import { LAST_CELL } from "./storage";

export default function Command() {
  return <DashboardList profile={PROD} store={LAST_CELL} />;
}
