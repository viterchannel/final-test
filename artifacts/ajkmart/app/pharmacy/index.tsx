import { withServiceGuard } from "@/components/ServiceGuard";

export default withServiceGuard("pharmacy", () => import("./_Screen"));
