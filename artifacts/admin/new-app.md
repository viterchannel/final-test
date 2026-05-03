.
./new-app.md
./vite.config.ts
./package.json
./public
./public/images
./public/sw.js
./public/opengraph.jpg
./public/manifest.json
./public/favicon.svg
./requirements.yaml
./src
./src/main.tsx
./src/hooks
./src/index.css
./src/pages
./src/global.d.ts
./src/App.tsx
./src/lib
./src/components
./components.json
./index.html
./tsconfig.json

### ROUTING LOGIC
./src/hooks/use-admin.ts:    queryKey: ["admin-school-routes"],
./src/hooks/use-admin.ts:    queryFn: () => fetcher("/school-routes"),
./src/hooks/use-admin.ts:      fetcher("/school-routes", { method: "POST", body: JSON.stringify(data) }),
./src/hooks/use-admin.ts:    onSuccess: () => qc.invalidateQueries({ queryKey: ["admin-school-routes"] }),
./src/hooks/use-admin.ts:      fetcher(`/school-routes/${id}`, { method: "PATCH", body: JSON.stringify(data) }),
./src/hooks/use-admin.ts:    onSuccess: () => qc.invalidateQueries({ queryKey: ["admin-school-routes"] }),
./src/hooks/use-admin.ts:    mutationFn: (id: string) => fetcher(`/school-routes/${id}`, { method: "DELETE" }),
./src/hooks/use-admin.ts:    onSuccess: () => qc.invalidateQueries({ queryKey: ["admin-school-routes"] }),
./src/hooks/use-admin.ts:export const useSchoolSubscriptions = (routeId?: string) => {
./src/hooks/use-admin.ts:    queryKey: ["admin-school-subscriptions", routeId],
./src/hooks/use-admin.ts:    queryFn: () => fetcher(`/school-subscriptions${routeId ? `?routeId=${routeId}` : ""}`),
./src/hooks/use-admin.ts:    queryKey: ["admin-rider-route", userId, date ?? "session"],
./src/hooks/use-admin.ts:    queryFn: () => fetcher(`/riders/${userId}/route${qs}`),
./src/hooks/use-admin.ts:      queryKey: ["admin-rider-route", id, "session"],
./src/hooks/use-admin.ts:      queryFn: () => fetcher(`/riders/${id}/route?sinceOnline=true`),
./src/hooks/use-admin.ts:    points: ((r.data as { route?: Array<{ latitude: number; longitude: number }> } | undefined)?.route ?? [])
./src/pages/not-found.tsx:            Did you forget to add the page to the router?
./src/pages/settings-render.tsx:      { fkey: "feature_chat",          label: "In-App Chat / WhatsApp",  icon: "💬", desc: "Chat icon in customer app — routes to WhatsApp support",          apps: "📱 Customer only",                        enforcement: "client" as const },
./src/pages/settings-render.tsx:      { fkey: "feature_live_tracking", label: "Live GPS Order Tracking",  icon: "📍", desc: "Customer can see rider's real-time location on map while en-route", apps: "📱 Customer  •  🏍️ Rider",             enforcement: "both" as const },
./src/pages/settings-render.tsx:              <p className="text-xs text-pink-700 mt-1">School Shift per-ride nahi, per-route monthly subscription hai. Iske routes aur fares Rides → School Shift tab se manage hote hain. Is section mein koi fare setting nahi hai.</p>
./src/pages/error-monitor.tsx:  { value: "route_error", label: "Route Error" },
./src/pages/error-monitor.tsx:  route_error:         "Route Error",
./src/pages/error-monitor.tsx:      causes.push("Unhandled exception in server-side route handler");
./src/pages/error-monitor.tsx:      fixes.push("Add proper try/catch in all route handlers");
./src/pages/error-monitor.tsx:    case "route_error":
./src/pages/error-monitor.tsx:      causes.push("Incorrect URL pattern or missing route registration");
./src/pages/error-monitor.tsx:      consequences.push("Endpoint is completely down — all users hitting this route are affected");
./src/pages/error-monitor.tsx:      fixes.push("Check the route registration and middleware order");
./src/pages/error-monitor.tsx:      fixes.push("Add global error handler middleware to catch unhandled route errors");
./src/pages/error-monitor.tsx:                {["ui_error", "api_error", "frontend_crash", "db_error", "route_error", "unhandled_exception"].map(t => (
./src/pages/rides.tsx:  const { data: routesData, isLoading } = useSchoolRoutes();
./src/pages/rides.tsx:  const [form, setForm] = useState({ routeName: "", schoolName: "", schoolNameUrdu: "", fromArea: "", fromAreaUrdu: "", toAddress: "", monthlyPrice: "", morningTime: "7:30 AM", afternoonTime: "", capacity: "30", vehicleType: "school_shift", notes: "", isActive: true, sortOrder: "0" });
./src/pages/rides.tsx:  const routes = routesData?.routes || [];
./src/pages/rides.tsx:  const openAdd = () => { setEditing(null); setForm({ routeName: "", schoolName: "", schoolNameUrdu: "", fromArea: "", fromAreaUrdu: "", toAddress: "", monthlyPrice: "", morningTime: "7:30 AM", afternoonTime: "", capacity: "30", vehicleType: "school_shift", notes: "", isActive: true, sortOrder: "0" }); setShowForm(true); };
./src/pages/rides.tsx:    if (!form.routeName || !form.schoolName || !form.fromArea || !form.toAddress || !form.monthlyPrice) { toast({ title: "Fill required fields", variant: "destructive" }); return; }
./src/pages/rides.tsx:      {isLoading ? <Card className="p-8 rounded-2xl text-center"><p className="text-muted-foreground">Loading...</p></Card> : routes.length === 0 ? (
./src/pages/rides.tsx:        <Card className="p-10 rounded-2xl text-center"><Bus className="w-10 h-10 text-muted-foreground mx-auto mb-3" /><p className="font-bold text-muted-foreground">No routes yet</p></Card>
./src/pages/rides.tsx:          {routes.map((r: any) => (
./src/pages/rides.tsx:                  <p className="font-bold text-sm">{r.routeName}</p>
./src/pages/rides.tsx:                  <button onClick={() => { setEditing(r); setForm({ routeName: r.routeName, schoolName: r.schoolName, schoolNameUrdu: r.schoolNameUrdu || "", fromArea: r.fromArea, fromAreaUrdu: r.fromAreaUrdu || "", toAddress: r.toAddress, monthlyPrice: String(r.monthlyPrice), morningTime: r.morningTime || "7:30 AM", afternoonTime: r.afternoonTime || "", capacity: String(r.capacity), vehicleType: r.vehicleType, notes: r.notes || "", isActive: r.isActive, sortOrder: String(r.sortOrder) }); setShowForm(true); }} className="text-muted-foreground hover:text-blue-600"><Pencil className="w-4 h-4" /></button>
./src/pages/rides.tsx:              <div className="col-span-2"><label className="text-xs font-medium text-muted-foreground">Route Name</label><Input value={form.routeName} onChange={e => setForm(f => ({...f, routeName: e.target.value}))} className="rounded-xl mt-1" /></div>
./src/pages/rides.tsx:              Are you sure you want to delete <span className="font-semibold">"{deleteTarget?.routeName}"</span>? This cannot be undone.
./src/pages/banners.tsx:  { value: "route", label: "In-App Route" },
./src/pages/banners.tsx:                      form.linkType === "route" ? "/mart  or  /food  or  /ride" :
./src/pages/live-riders-map.tsx:  const pts: Array<[number, number]> = (data?.route ?? []).map(
./src/pages/live-riders-map.tsx:  const [routeDate, setRouteDate] = useState(() => new Date().toISOString().slice(0, 10));
./src/pages/live-riders-map.tsx:  const { data: routeData } = useRiderRoute(selectedId, routeDate);
./src/pages/live-riders-map.tsx:  const routePoints: RoutePoint[] = routeData?.route ?? [];
./src/pages/live-riders-map.tsx:  const sliderMax = Math.max(0, routePoints.length - 1);
./src/pages/live-riders-map.tsx:  const visibleRoute = routePoints.slice(0, sliderIndex + 1);
./src/pages/live-riders-map.tsx:  const loginPoint = routePoints[0] ?? null;
./src/pages/live-riders-map.tsx:      pls.push({ id: "route", positions: polylinePositions, color: "#6366f1", weight: 3, opacity: 0.75 });
./src/pages/live-riders-map.tsx:                                value={routeDate}
./src/pages/live-riders-map.tsx:                            {routePoints.length > 1 ? (
./src/pages/live-riders-map.tsx:                                  <span className="flex items-center gap-1"><Route className="w-3 h-3" /> {routePoints.length} pts</span>
./src/pages/live-riders-map.tsx:                                <p className="text-[10px] text-muted-foreground mt-1.5 text-center">Drag to replay route history</p>
./src/pages/live-riders-map.tsx:                              <p className="text-xs text-muted-foreground text-center py-4">No route data for selected date</p>
./src/pages/parcel.tsx:                <TableHead className="font-semibold">{T("route")}</TableHead>
./src/pages/van.tsx:  id: string; routeId: string; vehicleId?: string; driverId?: string; departureTime: string;
./src/pages/van.tsx:  routeName?: string; vehiclePlate?: string; driverName?: string; vanCode?: string | null;
./src/pages/van.tsx:  passengerName?: string; tripStatus?: string; createdAt: string; routeName?: string;
./src/pages/van.tsx:  routeFrom?: string; routeTo?: string; departureTime?: string; userName?: string; userPhone?: string;
./src/pages/van.tsx:  const { data: routes = [], isLoading } = useQuery<VanRoute[]>({
./src/pages/van.tsx:    queryKey: ["van-admin-routes"],
./src/pages/van.tsx:    queryFn: () => vanFetch("/admin/routes"),
./src/pages/van.tsx:      return id ? vanFetch(`/admin/routes/${id}`, { method: "PATCH", body: JSON.stringify(payload) })
./src/pages/van.tsx:        : vanFetch("/admin/routes", { method: "POST", body: JSON.stringify(payload) });
./src/pages/van.tsx:    onSuccess: () => { qc.invalidateQueries({ queryKey: ["van-admin-routes"] }); setEditRoute(null); setNewRouteOpen(false); toast({ title: "Route saved" }); },
./src/pages/van.tsx:    mutationFn: (id: string) => vanFetch(`/admin/routes/${id}`, { method: "DELETE" }),
./src/pages/van.tsx:    onSuccess: () => { qc.invalidateQueries({ queryKey: ["van-admin-routes"] }); toast({ title: "Route deactivated" }); },
./src/pages/van.tsx:        <span className="text-sm text-muted-foreground">{routes.length} route{routes.length !== 1 ? "s" : ""}</span>
./src/pages/van.tsx:            {routes.map(r => (
./src/pages/van.tsx:                  <Button size="icon" variant="ghost" className="text-red-500 hover:text-red-700" onClick={() => { if (confirm("Deactivate this route?")) deleteMut.mutate(r.id); }}><Trash2 className="w-4 h-4" /></Button>
./src/pages/van.tsx:            Seat Inventory — {schedule.routeName || "Schedule"}
./src/pages/van.tsx:  const [form, setForm] = useState({ routeId: "", vehicleId: "", driverId: "", departureTime: "07:00", returnTime: "", daysOfWeek: [1,2,3,4,5,6] });
./src/pages/van.tsx:  const { data: routes = [] } = useQuery<VanRoute[]>({
./src/pages/van.tsx:    queryKey: ["van-admin-routes"],
./src/pages/van.tsx:    queryFn: () => vanFetch("/admin/routes"),
./src/pages/van.tsx:        routeId: form.routeId, vehicleId: form.vehicleId || null, driverId: form.driverId || null,
./src/pages/van.tsx:    setForm({ routeId: "", vehicleId: "", driverId: "", departureTime: "07:00", returnTime: "", daysOfWeek: [1,2,3,4,5,6] });
./src/pages/van.tsx:      routeId: s.routeId,
./src/pages/van.tsx:        <Select value={form.routeId} onValueChange={v => setForm(f => ({ ...f, routeId: v }))}>
./src/pages/van.tsx:          <SelectTrigger><SelectValue placeholder="Select route" /></SelectTrigger>
./src/pages/van.tsx:          <SelectContent>{routes.filter(r => r.isActive).map(r => <SelectItem key={r.id} value={r.id}>{r.name}</SelectItem>)}</SelectContent>
./src/pages/van.tsx:          Route: {editSchedule.routeName || editSchedule.routeId}
./src/pages/van.tsx:                <TableCell className="font-medium text-sm">{s.routeName || s.routeId}</TableCell>
./src/pages/van.tsx:            <Button onClick={() => createMut.mutate()} disabled={!form.routeId || createMut.isPending}>
./src/pages/van.tsx:                  {b.routeName || "—"}
./src/pages/van.tsx:          <p className="text-sm text-muted-foreground">Manage commercial van routes, schedules, vehicles, drivers and seat bookings</p>
./src/pages/van.tsx:      <Tabs defaultValue="routes">
./src/pages/van.tsx:          <TabsTrigger value="routes"><Route className="w-4 h-4 mr-1.5" />Routes</TabsTrigger>
./src/pages/van.tsx:        <TabsContent value="routes"><RoutesTab /></TabsContent>
./src/pages/launch-control.tsx:      { key: "feature_van",      label: "Van Service",       desc: "Shared van school/office routes" },

### LOGIN & AUTH LOGIC
./package.json:    "class-variance-authority": "catalog:",
./requirements.yaml:  - path: "artifacts/admin/public/images/login-bg.png"
./requirements.yaml:  - "Admin auth uses x-admin-secret header for all API calls"
./src/hooks/use-admin.ts:      fetcher("/auth", {
./src/pages/login.tsx:  const login = useAdminLogin();
./src/pages/login.tsx:    login.mutate(
./src/pages/login.tsx:          if (data.success && data.token) {
./src/pages/login.tsx:            setToken(data.token);
./src/pages/login.tsx:          src={`${import.meta.env.BASE_URL}images/login-bg.png`}
./src/pages/login.tsx:              disabled={login.isPending || !username.trim() || !password.trim()}
./src/pages/login.tsx:              {login.isPending ? (
./src/pages/sos-alerts.tsx:    const token = sessionStorage.getItem("ajkmart_admin_token") ?? "";
./src/pages/sos-alerts.tsx:      auth: { adminToken: token },
./src/pages/sos-alerts.tsx:      extraHeaders: { "x-admin-token": token },
./src/pages/settings.tsx:  jwt:          { label: "JWT & Sessions",      icon: KeyRound,     color: "text-indigo-600",  bg: "bg-indigo-50",  activeBg: "bg-indigo-600",  description: "Access token, refresh token and 2FA challenge timeouts" },
./src/pages/faq-management.tsx:    Authorization: `Bearer ${sessionStorage.getItem("ajkmart_admin_token")}`,
./src/pages/popups.tsx:    const token = sessionStorage.getItem("ajkmart_admin_token");
./src/pages/popups.tsx:    if (!token) return "support";
./src/pages/popups.tsx:    const payload = JSON.parse(atob(token.split(".")[1]!));
./src/pages/popups.tsx:  const handleSubmit = () => {
./src/pages/settings-system.tsx:  const adminSecret = sessionStorage.getItem("ajkmart_admin_token") || "";
./src/pages/settings-system.tsx:      headers: { "x-admin-token": adminSecret, "Content-Type": "application/json", ...(opts?.headers || {}) },
./src/pages/settings-system.tsx:      const res = await fetch("/api/admin/system/backup", { headers: { "x-admin-token": adminSecret } });
./src/pages/settings-system.tsx:        headers: { "x-admin-token": adminSecret, "Content-Type": "application/json" },
./src/pages/settings-system.tsx:      const res = await fetch(`/api/admin/system/export/${endpoint}${qs}`, { headers: { "x-admin-token": adminSecret } });
./src/pages/promotions-hub.tsx:  const handleSubmit = () => {
./src/pages/promotions-hub.tsx:            <Button onClick={handleSubmit} disabled={mutation.isPending} className="flex-1 rounded-xl">
./src/pages/promotions-hub.tsx:  const handleSubmit = () => {
./src/pages/promotions-hub.tsx:              <Button onClick={handleSubmit} disabled={mutation.isPending} className="flex-1 rounded-xl">
./src/pages/communication.tsx:  tokensUsed?: number;
./src/pages/communication.tsx:  tokens_used?: number;
./src/pages/communication.tsx:    const token = getToken();
./src/pages/communication.tsx:      auth: { adminToken: token },
./src/pages/communication.tsx:      query: { adminToken: token ?? undefined, rooms: "admin-fleet" },
./src/pages/communication.tsx:              <TableCell>{log.tokensUsed || log.tokens_used || 0}</TableCell>
./src/pages/communication.tsx:  const handleSubmit = async () => {
./src/pages/communication.tsx:          <Button onClick={handleSubmit} disabled={saving}>{saving ? "Saving..." : (editId ? "Save Changes" : "Create")}</Button>
./src/pages/riders.tsx:  const handleSubmit = () => {
./src/pages/riders.tsx:            <Button onClick={handleSubmit}
./src/pages/loyalty.tsx:  const handleSubmit = () => {
./src/pages/loyalty.tsx:          onClick={handleSubmit}
./src/pages/settings-render.tsx:  "security_session_days","security_admin_token_hrs","security_rider_token_days",
./src/pages/settings-render.tsx:  "security_login_max_attempts","security_lockout_minutes",
./src/pages/settings-render.tsx:  "wa_phone_number_id","wa_access_token","wa_verify_token","wa_business_account_id","wa_order_template","wa_otp_template",
./src/pages/settings-render.tsx:      { fkey: "feature_new_users",    label: "New User Registration",  icon: "👤", desc: "Blocks all new sign-ups at auth API — existing users unaffected",  apps: "📱 Customer  •  🏪 Vendor  •  🏍️ Rider", enforcement: "api" as const },
./src/pages/settings-render.tsx:            <span className="text-[10px] text-slate-400 font-mono bg-slate-100 px-1.5 py-0.5 rounded">wallet / auth / customer API</span>
./src/pages/settings-render.tsx:      app_tagline:      "Subtitle on the customer login screen",
./src/pages/settings-render.tsx:      business_address: "Shown on login screen footer (vendor) and profile footer",
./src/pages/settings-render.tsx:              sub="Force all riders to set up two-factor authentication"
./src/pages/settings-render.tsx:            <NField k="email_template_magic_html" label="Magic Link Email HTML" hint="Passwordless login email — include {link} placeholder" rows={5} />
./src/pages/search-analytics.tsx:  return { Authorization: `Bearer ${sessionStorage.getItem("ajkmart_admin_token")}` };
./src/pages/promo-codes.tsx:  const handleSubmit = () => {
./src/pages/promo-codes.tsx:              onClick={handleSubmit}
./src/pages/vendors.tsx:  const handleSubmit = () => {
./src/pages/vendors.tsx:            <Button onClick={handleSubmit}
./src/pages/reviews.tsx:    const token = getToken();
./src/pages/reviews.tsx:    const res = await fetch(url, { headers: token ? { "x-admin-token": token } : {} });
./src/pages/error-monitor.tsx:  if (msg.includes("auth") || msg.includes("token") || msg.includes("unauthorized") || msg.includes("401")) {
./src/pages/error-monitor.tsx:    causes.push("Authentication token expired, revoked, or tampered with");
./src/pages/error-monitor.tsx:    fixes.push("Implement automatic silent token refresh before expiry");
./src/pages/error-monitor.tsx:    fixes.push("Handle 401 globally and redirect to login with a clear message");
./src/pages/users.tsx:  const handleSubmit = () => {
./src/pages/users.tsx:            <p className="text-sm text-muted-foreground">User account has been created. Share the temporary password below with the user — they will be prompted to change it on first login.</p>
./src/pages/users.tsx:            <label className="text-xs font-semibold text-muted-foreground uppercase tracking-wider">Username <span className="text-muted-foreground font-normal normal-case">(optional, for password login)</span></label>
./src/pages/users.tsx:              : <p className="text-[11px] text-muted-foreground">Min 8 chars, 1 uppercase letter, 1 number. User must change on first login.</p>
./src/pages/users.tsx:              onClick={handleSubmit}
./src/pages/users.tsx:      toast({ title: "OTP cleared", description: "User must re-authenticate on next login." });
./src/pages/users.tsx:      toast({ title: "2FA disabled", description: "Two-factor authentication has been turned off for this user." });
./src/pages/users.tsx:                    <p className="text-xs text-muted-foreground">Allow login without OTP for a limited window</p>
./src/pages/users.tsx:              <Button variant="outline" size="sm" onClick={() => { sessionStorage.removeItem("ajkmart_admin_token"); window.location.href = (import.meta.env.BASE_URL?.replace(/\/$/, "") || "") + "/login"; }} className="rounded-xl border-red-200 text-red-700 hover:bg-red-100">
./src/pages/otp-control.tsx:  const token = getToken() ?? "";
./src/pages/otp-control.tsx:    headers: { "Content-Type": "application/json", "x-admin-token": token },
./src/pages/otp-control.tsx:    window.location.href = (import.meta.env.BASE_URL ?? "/") + "login";
./src/pages/otp-control.tsx:  /* ── Load recent audit entries (no-OTP logins only) ── */
./src/pages/otp-control.tsx:          e.event === "login_otp_bypass" || e.event === "login_global_otp_bypass"
./src/pages/otp-control.tsx:    login_otp_bypass: "Per-user bypass",
./src/pages/otp-control.tsx:    login_global_otp_bypass: "Global suspension",
./src/pages/otp-control.tsx:                    : "All users must verify OTP on login."}
./src/pages/otp-control.tsx:          Every login that skipped OTP (via per-user bypass or global suspension) is recorded here.
./src/pages/otp-control.tsx:            No no-OTP logins recorded yet.
./src/pages/otp-control.tsx:                <div className={`w-1.5 h-1.5 rounded-full flex-shrink-0 ${row.event === "login_otp_bypass" ? "bg-blue-500" : "bg-orange-500"}`} />
./src/pages/sms-gateways.tsx:    { key: "authToken",  label: "Auth Token",   placeholder: "••••••••••", secret: true },
./src/pages/sms-gateways.tsx:    { key: "msg91Key",  label: "Auth Key",     placeholder: "MSG91 auth key", secret: true },
./src/pages/sms-gateways.tsx:    { key: "apiKey",    label: "API Key",      placeholder: "CM.com product token", secret: true },
./src/pages/sms-gateways.tsx:const emptyForm = { name: "", provider: "twilio", priority: 10, accountSid: "", authToken: "", fromNumber: "", msg91Key: "", senderId: "", apiKey: "", apiUrl: "" };
./src/pages/sms-gateways.tsx:    setForm({ name: gw.name, provider: gw.provider, priority: gw.priority, accountSid: "", authToken: "", fromNumber: gw.fromNumber ?? "", msg91Key: "", senderId: gw.senderId ?? "", apiKey: "", apiUrl: gw.apiUrl ?? "" });
./src/pages/broadcast.tsx:  const handleSubmit = (e: React.FormEvent) => {
./src/pages/broadcast.tsx:            <form onSubmit={handleSubmit} className="space-y-6">
./src/pages/support-chat.tsx:    Authorization: `Bearer ${sessionStorage.getItem("ajkmart_admin_token")}`,
./src/pages/security.tsx:type SecTab = "auth" | "authmethods" | "ratelimit" | "gps" | "passwords" | "uploads" | "fraud";
./src/pages/security.tsx:  { id: "auth",        label: "Auth & Sessions",  emoji: "🔐", active: "bg-indigo-600",  desc: "OTP bypass, MFA, login lockout, session durations, live lockouts" },
./src/pages/security.tsx:  { id: "authmethods", label: "Auth Methods",      emoji: "🔑", active: "bg-cyan-600",    desc: "Per-role login method toggles: Phone OTP, Email OTP, Username/Password, Social, Magic Link, 2FA, Biometric" },
./src/pages/security.tsx:  { id: "passwords",   label: "Passwords",         emoji: "🔑", active: "bg-amber-600",   desc: "Password policy, JWT rotation, token expiry" },
./src/pages/security.tsx:  const [secTab, setSecTab] = useState<SecTab>("auth");
./src/pages/security.tsx:  const adminToken  = sessionStorage.getItem("ajkmart_admin_token") || "";
./src/pages/security.tsx:  const apiHeaders  = { "Content-Type": "application/json", "x-admin-token": adminToken };
./src/pages/security.tsx:        fetch(`${window.location.origin}/api/admin/login-lockouts`,     { headers: apiHeaders }).then(checkOk),
./src/pages/security.tsx:  /* ── Auto-load live data when switching to auth or fraud tabs ── */
./src/pages/security.tsx:    if (secTab === "auth" || secTab === "fraud") fetchLiveData();
./src/pages/security.tsx:    if (secTab === "auth") fetchMfaStatus();
./src/pages/security.tsx:      security_admin_token_hrs:     { min: 1,   max: 720,    label: "Admin Token Expiry" },
./src/pages/security.tsx:      security_rider_token_days:    { min: 1,   max: 365,    label: "Rider Token Expiry" },
./src/pages/security.tsx:      const r = await fetch(`${window.location.origin}/api/admin/login-lockouts/${encodeURIComponent(phone)}`, {
./src/pages/security.tsx:      toast({ title: "Invalid Code", description: "Enter the 6-digit code from your authenticator app.", variant: "destructive" });
./src/pages/security.tsx:        method: "POST", headers: apiHeaders, body: JSON.stringify({ token: mfaToken }),
./src/pages/security.tsx:        toast({ title: "MFA Activated!", description: "Two-factor authentication is now enabled." });
./src/pages/security.tsx:        method: "DELETE", headers: apiHeaders, body: JSON.stringify({ token: disableToken }),
./src/pages/security.tsx:        toast({ title: "MFA Disabled", description: "Two-factor authentication has been disabled." });
./src/pages/security.tsx:      {secTab === "auth" && (
./src/pages/security.tsx:              <T k="security_mfa_required" label="Two-Factor Auth for Admin Login" sub="Adds TOTP code requirement at every login" />
./src/pages/security.tsx:              <N k="security_admin_token_hrs"  label="Admin Token Expiry"      suffix="hrs"  placeholder="24" hint="24 hrs = 1 day" />
./src/pages/security.tsx:              <N k="security_rider_token_days" label="Rider Token Expiry"      suffix="days" placeholder="30" />
./src/pages/security.tsx:              <span>After <strong>Max Attempts</strong> failures, the account is locked for <strong>Lockout Duration</strong>. Applies to customer, rider, and vendor logins.</span>
./src/pages/security.tsx:              <N k="security_login_max_attempts" label="Max Failed Login Attempts" placeholder="5"  hint="Before account lockout" />
./src/pages/security.tsx:              <p className="text-xs text-muted-foreground">Real-time locked accounts due to failed login / OTP attempts</p>
./src/pages/security.tsx:              <span>Set up TOTP-based two-factor authentication for your admin account using Google Authenticator, Authy, or any compatible app.</span>
./src/pages/security.tsx:                    <p className="text-xs text-green-700 mt-0.5">Your admin account is protected with TOTP two-factor authentication.</p>
./src/pages/security.tsx:                  <p className="text-xs font-semibold text-muted-foreground mb-2">To disable MFA, enter a valid 6-digit code from your authenticator app:</p>
./src/pages/security.tsx:                    <p className="text-xs font-bold text-foreground">Step 1 — Scan with your authenticator app</p>
./src/pages/security.tsx:                    <p className="text-xs text-amber-700 mt-0.5">Your admin account does not have two-factor authentication. Set it up for stronger security.</p>
./src/pages/security.tsx:      {secTab === "authmethods" && (
./src/pages/security.tsx:              Each auth method can be enabled or disabled per role (Customer, Rider, Vendor).
./src/pages/security.tsx:              { key: "auth_phone_otp_enabled",         label: "Phone OTP Login",          sub: "Send OTP via SMS to verify phone number" },
./src/pages/security.tsx:              { key: "auth_email_otp_enabled",         label: "Email OTP Login",          sub: "Send OTP via email to verify address" },
./src/pages/security.tsx:              { key: "auth_username_password_enabled", label: "Username / Password Login", sub: "Traditional username + password credentials" },
./src/pages/security.tsx:              { key: "auth_email_register_enabled",    label: "Email Registration",       sub: "Allow sign-up with email (no phone OTP)" },
./src/pages/security.tsx:              { key: "auth_magic_link_enabled",        label: "Magic Link Login",         sub: "Send one-click login link via email" },
./src/pages/security.tsx:              { key: "auth_2fa_enabled",               label: "Two-Factor Auth (TOTP)",   sub: "Require authenticator app code after login" },
./src/pages/security.tsx:              { key: "auth_biometric_enabled",         label: "Biometric Login",          sub: "Fingerprint / Face ID on mobile devices" },
./src/pages/security.tsx:              <span>Social logins require Client ID / App ID configured below. Per-role toggles above control availability.</span>
./src/pages/security.tsx:              <Toggle label="Google Login (legacy)" sub="Global on/off for Google Sign-In" checked={tog("auth_social_google")}
./src/pages/security.tsx:                onChange={v => handleToggle("auth_social_google", v)} isDirty={dirty("auth_social_google")} />
./src/pages/security.tsx:              <Toggle label="Facebook Login (legacy)" sub="Global on/off for Facebook Login" checked={tog("auth_social_facebook")}
./src/pages/security.tsx:                onChange={v => handleToggle("auth_social_facebook", v)} isDirty={dirty("auth_social_facebook")} />
./src/pages/security.tsx:                { key: "auth_google_enabled",   label: "Google Login (per-role)",   sub: "Per-role control for Google Sign-In" },
./src/pages/security.tsx:                { key: "auth_facebook_enabled", label: "Facebook Login (per-role)", sub: "Per-role control for Facebook Login" },
./src/pages/security.tsx:              <Toggle label="reCAPTCHA v3 Verification" sub="Require captcha on login / register / OTP" checked={tog("auth_captcha_enabled")}
./src/pages/security.tsx:                onChange={v => handleToggle("auth_captcha_enabled", v)} isDirty={dirty("auth_captcha_enabled")} />
./src/pages/security.tsx:              <Field label="Trusted Device Expiry" value={val("auth_trusted_device_days", "30")} onChange={v => handleChange("auth_trusted_device_days", v)}
./src/pages/security.tsx:                isDirty={dirty("auth_trusted_device_days")} type="number" suffix="days" placeholder="30" hint="Skip 2FA on trusted devices" />
./src/pages/security.tsx:              <N k="security_admin_token_hrs"   label="Admin Token Expiry"  suffix="hrs"  placeholder="24" />
./src/pages/security.tsx:              <N k="security_rider_token_days"  label="Rider Token Expiry"  suffix="days" placeholder="30" />
./src/pages/security.tsx:              <T k="security_mfa_required" label="Require 2FA for Admin"  sub="TOTP code required at every login" />
./src/pages/rides.tsx:        const tok  = cfg?.token ?? "";
./src/pages/rides.tsx:            url: `https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/256/{z}/{x}/{y}@2x?access_token=${tok}`,
./src/pages/rides.tsx:    const token = sessionStorage.getItem("ajkmart_admin_token") ?? "";
./src/pages/rides.tsx:      auth: { adminToken: token },
./src/pages/rides.tsx:  const handleSubmit = async () => {
./src/pages/rides.tsx:      {showAdd && !editId && <ServiceFormPanel isNew form={form} setForm={setForm} onSubmit={handleSubmit} onCancel={resetForm} isPending={isPending} />}
./src/pages/rides.tsx:                {editId === svc.id && <ServiceFormPanel isNew={false} form={form} setForm={setForm} onSubmit={handleSubmit} onCancel={resetForm} isPending={isPending} />}
./src/pages/rides.tsx:    const token = sessionStorage.getItem("ajkmart_admin_token") ?? "";
./src/pages/rides.tsx:      auth: { adminToken: token },
./src/pages/kyc.tsx:  return { Authorization: `Bearer ${sessionStorage.getItem("ajkmart_admin_token")}`, "Content-Type": "application/json" };
./src/pages/settings-payment.tsx:        headers: { "x-admin-token": sessionStorage.getItem("ajkmart_admin_token") || "" },
./src/pages/products.tsx:  const handleSubmit = (e: React.FormEvent) => {
./src/pages/products.tsx:          <form onSubmit={handleSubmit} className="space-y-4 mt-4">
./src/pages/live-riders-map.tsx:  token: string;
./src/pages/live-riders-map.tsx:    admin?: { provider: string; token: string; override: string };
./src/pages/live-riders-map.tsx:    customer?: { provider: string; token: string; override: string };
./src/pages/live-riders-map.tsx:    rider?: { provider: string; token: string; override: string };
./src/pages/live-riders-map.tsx:    vendor?: { provider: string; token: string; override: string };
./src/pages/live-riders-map.tsx:function resolveAdminProvider(config: MapConfig | undefined): { provider: string; token: string } {
./src/pages/live-riders-map.tsx:  if (!config) return { provider: "osm", token: "" };
./src/pages/live-riders-map.tsx:  if (adminOverride && adminOverride.provider) return { provider: adminOverride.provider, token: adminOverride.token };
./src/pages/live-riders-map.tsx:  return { provider: config.provider ?? "osm", token: config.token ?? "" };
./src/pages/live-riders-map.tsx:  const token = useFallback ? (config?.secondaryToken ?? "") : adminProv.token;
./src/pages/live-riders-map.tsx:    if (provider === "mapbox" && token)
./src/pages/live-riders-map.tsx:      return `https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/256/{z}/{x}/{y}@2x?access_token=${token}`;
./src/pages/live-riders-map.tsx:    if (provider === "google" && token)
./src/pages/live-riders-map.tsx:      return `https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}&key=${token}`;
./src/pages/live-riders-map.tsx:  }, [provider, token]);
./src/pages/live-riders-map.tsx:        token={adminToken}
./src/pages/live-riders-map.tsx:        token={adminToken}
./src/pages/live-riders-map.tsx:  const effectiveToken = quickProvider === "osm" ? "" : adminMapProv.token;
./src/pages/live-riders-map.tsx:    const token = sessionStorage.getItem("ajkmart_admin_token") ?? "";
./src/pages/live-riders-map.tsx:      auth: { adminToken: token },
./src/pages/live-riders-map.tsx:      extraHeaders: { "x-admin-token": token },
./src/pages/live-riders-map.tsx:  const loginPoint = routePoints[0] ?? null;
./src/pages/live-riders-map.tsx:    if (selectedId && loginPoint) {
./src/pages/live-riders-map.tsx:      ms.push({ id: "login-pin", lat: loginPoint.latitude, lng: loginPoint.longitude, label: "Login", iconHtml: `<div style="width:22px;height:22px;background:#6366f1;border:2px solid white;border-radius:4px;box-shadow:0 2px 4px rgba(0,0,0,0.25);display:flex;align-items:center;justify-content:center;font-size:11px">📍</div>`, iconSize: 22 });
./src/pages/live-riders-map.tsx:  }, [effectiveProvider, filteredRiders, customers, vendors, showRiders, showCustomers, showVendors, showSOS, sosAlerts, selectedId, loginPoint, replayPoint, sliderVal]);
./src/pages/live-riders-map.tsx:                  {selectedRider && loginPoint && (
./src/pages/live-riders-map.tsx:                    <Marker position={[loginPoint.latitude, loginPoint.longitude]} icon={makeLoginIcon()}>
./src/pages/live-riders-map.tsx:                          <p style={{ fontSize: 11, color: "#6366f1", margin: 0 }}>{new Date(loginPoint.createdAt).toLocaleTimeString()}</p>
./src/pages/van.tsx:const getToken = () => sessionStorage.getItem("ajkmart_admin_token");
./src/pages/van.tsx:  const token = getToken();
./src/pages/van.tsx:      ...(token ? { "x-admin-token": token } : {}),
./src/pages/van.tsx:  const token = getToken();
./src/pages/van.tsx:      ...(token ? { "x-admin-token": token } : {}),
./src/pages/app-management.tsx:                            Last login: {a.lastLoginAt ? new Date(a.lastLoginAt).toLocaleString("en-PK", { month: "short", day: "numeric", hour: "2-digit", minute: "2-digit" }) : "Never"}
./src/pages/launch-control.tsx:    keys: ["security_login_max_attempts", "security_lockout_minutes", "security_session_days", "security_gps_tracking", "security_spoof_detection"],
./src/pages/launch-control.tsx:  const adminSecret = sessionStorage.getItem("ajkmart_admin_token") ?? "";
./src/pages/launch-control.tsx:  const headers = { "Content-Type": "application/json", "x-admin-token": adminSecret };
./src/pages/settings-integrations.tsx:        const token = fcmDeviceToken.trim();
./src/pages/settings-integrations.tsx:        if (!token) {
./src/pages/settings-integrations.tsx:          toast({ title: "Device token required", description: "Enter an FCM device token to test push notifications", variant: "destructive" });
./src/pages/settings-integrations.tsx:        body["deviceToken"] = token;
./src/pages/settings-integrations.tsx:  const waConfigured = waEnabled && !!(val("wa_phone_number_id") && val("wa_access_token"));
./src/pages/settings-integrations.tsx:                ? "🔒 Strict — OTP required; login blocked if no provider configured."
./src/pages/settings-integrations.tsx:                    <span className="text-xs font-semibold text-foreground">Send test push to FCM device token</span>
./src/pages/settings-integrations.tsx:                    placeholder="FCM device registration token"
./src/pages/settings-integrations.tsx:                  <S label="Auth Token" k="sms_api_key" placeholder="your_auth_token" />
./src/pages/settings-integrations.tsx:                  <S label="Permanent Access Token" k="wa_access_token" placeholder="EAAxxxxxxx..." />
./src/pages/settings-integrations.tsx:                <S label="Webhook Verify Token (set same in Meta Developer Console)" k="wa_verify_token" placeholder="my_secure_verify_token_123" />
./src/pages/settings-integrations.tsx:                    placeholder={analyticsPlatform === "google" ? "G-XXXXXXXXXX" : "your_token"} mono />
./src/pages/settings-security.tsx:type SecTab = "auth" | "ratelimit" | "gps" | "passwords" | "uploads" | "fraud" | "admin";
./src/pages/settings-security.tsx:  { id: "auth",      label: "Auth & Sessions", emoji: "🔐", active: "bg-indigo-600",  desc: "OTP, MFA, login lockout, session expiry" },
./src/pages/settings-security.tsx:  { id: "passwords", label: "Passwords",       emoji: "🔑", active: "bg-amber-600",   desc: "Password policy, JWT & token expiry" },
./src/pages/settings-security.tsx:  const [secTab, setSecTab] = useState<SecTab>("auth");
./src/pages/settings-security.tsx:  const adminSecret = sessionStorage.getItem("ajkmart_admin_token") || "";
./src/pages/settings-security.tsx:  const apiHeaders  = { "Content-Type": "application/json", "x-admin-token": adminSecret };
./src/pages/settings-security.tsx:        fetch(`${window.location.origin}/api/admin/login-lockouts`,     { headers: apiHeaders }).then(r => r.json()),
./src/pages/settings-security.tsx:    if (secTab === "auth" || secTab === "fraud" || secTab === "admin") {
./src/pages/settings-security.tsx:    await fetch(`${window.location.origin}/api/admin/login-lockouts/${encodeURIComponent(phone)}`, {
./src/pages/settings-security.tsx:        method: "POST", headers: apiHeaders, body: JSON.stringify({ token: mfaToken }),
./src/pages/settings-security.tsx:        toast({ title: "MFA Activated!", description: "Two-factor authentication is now enabled for your account." });
./src/pages/settings-security.tsx:        method: "DELETE", headers: apiHeaders, body: JSON.stringify({ token: disableToken }),
./src/pages/settings-security.tsx:        toast({ title: "MFA Disabled", description: "Two-factor authentication has been disabled." });
./src/pages/settings-security.tsx:      {secTab === "auth" && (
./src/pages/settings-security.tsx:              <N k="security_admin_token_hrs"  label="Admin Token Expiry"        suffix="hrs"   placeholder="24" hint="24 hrs = 1 day" />
./src/pages/settings-security.tsx:              <N k="security_rider_token_days" label="Rider Token Expiry"        suffix="days"  placeholder="30" />
./src/pages/settings-security.tsx:              <span>After <strong>Max Attempts</strong> failures, the account is locked for <strong>Lockout Duration</strong>. Applies to customer, rider, and vendor logins.</span>
./src/pages/settings-security.tsx:              <N k="security_login_max_attempts" label="Max Failed Login Attempts" placeholder="5"  hint="Before account lockout" />
./src/pages/settings-security.tsx:              <N k="security_admin_token_hrs"   label="Admin Token Expiry"    suffix="hrs"  placeholder="24" />
./src/pages/settings-security.tsx:              <N k="security_rider_token_days"  label="Rider Token Expiry"    suffix="days" placeholder="30" />
./src/pages/settings-security.tsx:                  <CheckCircle2 className="w-4 h-4" /> MFA is <strong>active</strong> on your account. Your TOTP app is required for every login.
./src/pages/settings-security.tsx:                    <p className="text-[10px] text-muted-foreground">Can't scan? Enter this key manually in your authenticator app.</p>
./src/pages/settings-security.tsx:              <T k="security_mfa_required" label="Require 2FA for Admin"    sub="TOTP code required at every login" />
./src/App.tsx:import Login from "@/pages/login";
./src/App.tsx:/* Auto-logout when an authenticated query returns 401.
./src/App.tsx:   Guard: only remove token + redirect if a token was actually present — this
./src/App.tsx:   prevents pre-login query failures (expected 401s) from wiping a token that
./src/App.tsx:      msg.includes("unauthorized") ||
./src/App.tsx:    if (is401 && sessionStorage.getItem("ajkmart_admin_token")) {
./src/App.tsx:      sessionStorage.removeItem("ajkmart_admin_token");
./src/App.tsx:      window.location.href = `${base}/login`;
./src/App.tsx:    const token = sessionStorage.getItem("ajkmart_admin_token");
./src/App.tsx:    if (!token) {
./src/App.tsx:      setLocation("/login");
./src/App.tsx:      const parts = token.split(".");
./src/App.tsx:          sessionStorage.removeItem("ajkmart_admin_token");
./src/App.tsx:          setLocation("/login");
./src/App.tsx:      <Route path="/login" component={Login} />
./src/App.tsx:          const token = sessionStorage.getItem("ajkmart_admin_token");
./src/App.tsx:          if (token) {
./src/App.tsx:    /* Register admin push when token present */
./src/App.tsx:    const token = sessionStorage.getItem("ajkmart_admin_token");
./src/App.tsx:    if (token) {
./src/App.tsx:    /* Also listen for post-login storage events to init push */
./src/App.tsx:      if (e.key === "ajkmart_admin_token" && e.newValue) {
./src/lib/api.ts:const ADMIN_TOKEN_KEY = "ajkmart_admin_token";
./src/lib/api.ts:export const setToken = (token: string) => {
./src/lib/api.ts:  sessionStorage.setItem(ADMIN_TOKEN_KEY, token);
./src/lib/api.ts:  const token = getToken();
./src/lib/api.ts:  if (!token) return true;
./src/lib/api.ts:  const exp = decodeJwtExp(token);
./src/lib/api.ts:  const token = getToken();
./src/lib/api.ts:            ...(token ? { "x-admin-token": token } : {}),
./src/lib/api.ts:  const token = getToken();
./src/lib/api.ts:      ...(token ? { "x-admin-token": token } : {}),
./src/lib/api.ts:    if (res.status === 401 && token) {
./src/lib/api.ts:      if (currentToken === token) {
./src/lib/api.ts:        window.location.href = import.meta.env.BASE_URL + "login";
./src/lib/api.ts:  const token = getToken();
./src/lib/api.ts:      ...(token ? { "x-admin-token": token } : {}),
./src/lib/api.ts:    if (res.status === 401 && token) {
./src/lib/api.ts:      if (currentToken === token) {
./src/lib/api.ts:        window.location.href = import.meta.env.BASE_URL + "login";
./src/lib/useLanguage.ts:      // If there is no auth token the user is on the login page — skip all
./src/lib/useLanguage.ts:      // API calls entirely.  Making unauthenticated calls here triggered a
./src/lib/useLanguage.ts:      // logged in and api.ts would delete the freshly-stored token, causing
./src/lib/push.ts:    const adminToken = sessionStorage.getItem("ajkmart_admin_token") ?? "";
./src/lib/push.ts:      body: JSON.stringify({ endpoint: sub.endpoint, p256dh: sub.toJSON().keys?.p256dh, auth: sub.toJSON().keys?.auth, role: "admin" }),
./src/lib/platformConfig.ts:  // Skip the API call if there is no admin token — this function is called
./src/lib/platformConfig.ts:  // at app startup (main.tsx), which runs before login. Making an
./src/lib/platformConfig.ts:  // unauthenticated request here causes a 401 that the api.ts handler could
./src/lib/platformConfig.ts:  // use to clear a freshly-saved login token (race condition).
./src/lib/platformConfig.ts:  if (!sessionStorage.getItem("ajkmart_admin_token")) return;
./src/lib/analytics.ts:      init: (token: string, opts?: Record<string, unknown>) => void;
./src/lib/analytics.ts:function _initMixpanel(token: string, debug: boolean): void {
./src/lib/analytics.ts:    window.mixpanel?.init(token, { debug });
./src/lib/searchIndex.ts:    keywords: ["security", "otp", "mfa", "2fa", "sessions", "ip blocking", "audit log", "login attempts", "lockout", "audit logs"],
./src/lib/searchIndex.ts:    romanUrduKeywords: ["security", "otp", "session", "ip block", "audit log", "login"],
./src/lib/searchIndex.ts:    subtitle: "OTP config, login lockout, IP whitelist",
./src/lib/searchIndex.ts:    keywords: ["security settings", "otp settings", "mfa", "2fa", "session expiry", "ip whitelist", "login lockout", "otp cooldown"],
./src/lib/searchIndex.ts:    romanUrduKeywords: ["security settings", "otp", "mfa", "session expiry", "ip whitelist", "login lockout"],
./src/components/layout/AdminLayout.tsx:  const [socketToken, setSocketToken] = useState(() => sessionStorage.getItem("ajkmart_admin_token") ?? "");
./src/components/layout/AdminLayout.tsx:      setLocation("/login");
./src/components/layout/AdminLayout.tsx:    const getAdminToken = () => sessionStorage.getItem("ajkmart_admin_token") ?? "";
./src/components/layout/AdminLayout.tsx:      auth: (cb: (data: Record<string, string>) => void) => cb({ adminToken: getAdminToken() }),
./src/components/layout/AdminLayout.tsx:    setLocation("/login");
./src/components/CommandPalette.tsx:    const token = getToken();
./src/components/CommandPalette.tsx:    if (!token) { toast({ title: "Not authenticated", variant: "destructive" }); return; }
./src/components/CommandPalette.tsx:        headers: { "Content-Type": "application/json", "x-admin-token": token },
./src/components/CommandPalette.tsx:  /* ── AI search (authenticated with x-admin-token) ── */
./src/components/CommandPalette.tsx:      const token = getToken();
./src/components/CommandPalette.tsx:      if (token) headers["x-admin-token"] = token;
./src/components/UniversalMap.tsx: * Map provider and API token are fetched from /api/maps/config (DB-managed)
./src/components/UniversalMap.tsx:  /** Mapbox access token / Google Maps API key (fetched from backend) */
./src/components/UniversalMap.tsx:  token?: string;
./src/components/UniversalMap.tsx:  token,
./src/components/UniversalMap.tsx:    if (provider === "mapbox" && token) {
./src/components/UniversalMap.tsx:      return `https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/256/{z}/{x}/{y}@2x?access_token=${token}`;
./src/components/UniversalMap.tsx:    if (provider === "google" && token) {
./src/components/UniversalMap.tsx:      return `https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}&key=${token}`;
./src/components/UniversalMap.tsx:  }, [provider, token]);
./src/components/UniversalMap.tsx:      const { token = "", center, zoom = 12, markers = [], polylines = [], style, className } = props;
./src/components/UniversalMap.tsx:          mapboxAccessToken={token}
./src/components/UniversalMap.tsx:function GoogleMap({ token = "", center, zoom = 12, markers = [], polylines = [], style, className }: UniversalMapProps) {
./src/components/UniversalMap.tsx:    if (!token || !mapRef.current) return;
./src/components/UniversalMap.tsx:    ensureGoogleMapsLoaded(token).then(() => {
./src/components/UniversalMap.tsx:    }).catch(() => { /* loader failure — token invalid or network error */ });
./src/components/UniversalMap.tsx:  }, [token]);
./src/components/UniversalMap.tsx:  if (!token) {
./src/components/UniversalMap.tsx:  if (props.provider === "mapbox" && props.token) {
./src/components/MapsMgmtSection.tsx:  const token = getToken();
./src/components/MapsMgmtSection.tsx:      ...(token ? { "x-admin-token": token } : {}),
./src/components/MapsMgmtSection.tsx:            setupNote="Create a token at account.mapbox.com → Access Tokens. Enable: styles:read, tiles:read. Restrict to your domain."
./src/components/ui/sidebar.tsx:import { cva, VariantProps } from "class-variance-authority"
./src/components/ui/button-group.tsx:import { cva, type VariantProps } from "class-variance-authority"
./src/components/ui/field.tsx:import { cva, type VariantProps } from "class-variance-authority"
./src/components/ui/navigation-menu.tsx:import { cva } from "class-variance-authority"
./src/components/ui/empty.tsx:import { cva, type VariantProps } from "class-variance-authority"
./src/components/ui/toggle-group.tsx:import { type VariantProps } from "class-variance-authority"
./src/components/ui/input-group.tsx:import { cva, type VariantProps } from "class-variance-authority"
./src/components/ui/button.tsx:import { cva, type VariantProps } from "class-variance-authority"
./src/components/ui/label.tsx:import { cva, type VariantProps } from "class-variance-authority"
./src/components/ui/item.tsx:import { cva, type VariantProps } from "class-variance-authority"
./src/components/ui/badge.tsx:import { cva, type VariantProps } from "class-variance-authority"
./src/components/ui/toggle.tsx:import { cva, type VariantProps } from "class-variance-authority"
./src/components/ui/alert.tsx:import { cva, type VariantProps } from "class-variance-authority"
./src/components/ui/sheet.tsx:import { cva, type VariantProps } from "class-variance-authority"
./src/components/ui/toast.tsx:import { cva, type VariantProps } from "class-variance-authority"

### API ENDPOINTS
./public/sw.js:self.addEventListener("fetch", (e) => {
./public/sw.js:    e.respondWith(fetch(e.request).catch(() => new Response("Offline", { status: 503 })));
./public/sw.js:    caches.match(e.request).then((cached) => cached || fetch(e.request).then((res) => {
./src/hooks/use-admin.ts:import { fetcher } from "@/lib/api";
./src/hooks/use-admin.ts:      fetcher("/auth", {
./src/hooks/use-admin.ts:    queryFn: () => fetcher("/stats"),
./src/hooks/use-admin.ts:    refetchInterval: REFETCH_INTERVAL,
./src/hooks/use-admin.ts:    queryFn: () => fetcher(`/users${params}`),
./src/hooks/use-admin.ts:    refetchInterval: REFETCH_INTERVAL,
./src/hooks/use-admin.ts:    queryFn: () => fetcher(`/users/search-riders?q=${encodeURIComponent(q)}&limit=20&onlineOnly=${onlineOnly}`),
./src/hooks/use-admin.ts:    queryFn: () => fetcher("/users/pending"),
./src/hooks/use-admin.ts:    refetchInterval: 15_000,
./src/hooks/use-admin.ts:      fetcher(`/users/${id}/approve`, { method: "POST", body: JSON.stringify({ note }) }),
./src/hooks/use-admin.ts:      fetcher(`/users/${id}/reject`, { method: "POST", body: JSON.stringify({ note }) }),
./src/hooks/use-admin.ts:      fetcher(`/users/${id}`, {
./src/hooks/use-admin.ts:      fetcher(`/users/${id}/wallet-topup`, {
./src/hooks/use-admin.ts:    queryFn: () => fetcher("/orders"),
./src/hooks/use-admin.ts:    refetchInterval: REFETCH_INTERVAL,
./src/hooks/use-admin.ts:      fetcher(`/orders/${id}/status`, {
./src/hooks/use-admin.ts:    queryFn: () => fetcher("/rides"),
./src/hooks/use-admin.ts:    refetchInterval: RIDES_REFETCH_INTERVAL,
./src/hooks/use-admin.ts:      fetcher(`/rides/${id}/status`, {
./src/hooks/use-admin.ts:    queryFn: () => fetcher("/pharmacy-enriched"),
./src/hooks/use-admin.ts:    refetchInterval: REFETCH_INTERVAL,
./src/hooks/use-admin.ts:      fetcher(`/pharmacy-orders/${id}/status`, {
./src/hooks/use-admin.ts:    queryFn: () => fetcher("/parcel-enriched"),
./src/hooks/use-admin.ts:    refetchInterval: REFETCH_INTERVAL,
./src/hooks/use-admin.ts:      fetcher(`/parcel-bookings/${id}/status`, {
./src/hooks/use-admin.ts:      fetcher("/users", {
./src/hooks/use-admin.ts:    mutationFn: (id: string) => fetcher(`/users/${id}`, { method: "DELETE" }),
./src/hooks/use-admin.ts:    queryFn: () => fetcher(`/users/${userId}/activity`),
./src/hooks/use-admin.ts:      const res = await fetch(`${apiBase}/api/categories`);
./src/hooks/use-admin.ts:      if (!res.ok) throw new Error("Failed to fetch categories");
./src/hooks/use-admin.ts:    queryFn: () => fetcher("/products"),
./src/hooks/use-admin.ts:    refetchInterval: REFETCH_INTERVAL,
./src/hooks/use-admin.ts:      fetcher("/products", {
./src/hooks/use-admin.ts:      fetcher(`/products/${id}`, {
./src/hooks/use-admin.ts:      fetcher(`/products/${id}`, {
./src/hooks/use-admin.ts:    queryFn: () => fetcher("/products/pending"),
./src/hooks/use-admin.ts:    refetchInterval: 30_000,
./src/hooks/use-admin.ts:      fetcher(`/products/${id}/approve`, { method: "PATCH", body: JSON.stringify({ note }) }),
./src/hooks/use-admin.ts:      fetcher(`/products/${id}/reject`, { method: "PATCH", body: JSON.stringify({ reason }) }),
./src/hooks/use-admin.ts:      fetcher(`/orders/${id}/refund`, { method: "POST", body: JSON.stringify({ amount, reason }) }),
./src/hooks/use-admin.ts:      fetcher("/broadcast", {
./src/hooks/use-admin.ts:    queryFn: () => fetcher("/transactions-enriched"),
./src/hooks/use-admin.ts:    refetchInterval: REFETCH_INTERVAL,
./src/hooks/use-admin.ts:    queryFn: () => fetcher(url),
./src/hooks/use-admin.ts:    refetchInterval: REFETCH_INTERVAL,
./src/hooks/use-admin.ts:    queryFn: () => fetcher("/orders-stats"),
./src/hooks/use-admin.ts:    refetchInterval: REFETCH_INTERVAL,
./src/hooks/use-admin.ts:export const fetchOrdersExport = async (filters?: OrdersEnrichedFilters): Promise<any> => {
./src/hooks/use-admin.ts:  return fetcher(url);
./src/hooks/use-admin.ts:    queryFn: () => fetcher(query ? `/rides-enriched?${query}` : "/rides-enriched"),
./src/hooks/use-admin.ts:    refetchInterval: RIDES_REFETCH_INTERVAL,
./src/hooks/use-admin.ts:    queryFn: () => fetcher("/platform-settings"),
./src/hooks/use-admin.ts:      fetcher("/platform-settings", {
./src/hooks/use-admin.ts:  useQuery({ queryKey: ["admin-vendors"], queryFn: () => fetcher("/vendors"), refetchInterval: REFETCH_INTERVAL });
./src/hooks/use-admin.ts:  useQuery({ queryKey: ["admin-fleet-vendors"], queryFn: () => fetcher("/fleet/vendors"), refetchInterval: 60_000 });
./src/hooks/use-admin.ts:    mutationFn: ({ id, ...data }: any) => fetcher(`/vendors/${id}/status`, { method: "PATCH", body: JSON.stringify(data) }),
./src/hooks/use-admin.ts:      fetcher(`/vendors/${id}/payout`, { method: "POST", body: JSON.stringify({ amount, description }) }),
./src/hooks/use-admin.ts:      fetcher(`/vendors/${id}/credit`, { method: "POST", body: JSON.stringify({ amount, description }) }),
./src/hooks/use-admin.ts:  useQuery({ queryKey: ["admin-riders"], queryFn: () => fetcher("/riders"), refetchInterval: REFETCH_INTERVAL, staleTime: 0 });
./src/hooks/use-admin.ts:    mutationFn: ({ id, ...data }: any) => fetcher(`/riders/${id}/status`, { method: "PATCH", body: JSON.stringify(data) }),
./src/hooks/use-admin.ts:      fetcher(`/riders/${id}/payout`, { method: "POST", body: JSON.stringify({ amount, description }) }),
./src/hooks/use-admin.ts:      fetcher(`/riders/${id}/bonus`, { method: "POST", body: JSON.stringify({ amount, description }) }),
./src/hooks/use-admin.ts:    queryFn: () => fetcher(`/riders/${riderId}/penalties`),
./src/hooks/use-admin.ts:    queryFn: () => fetcher(`/riders/${riderId}/ratings`),
./src/hooks/use-admin.ts:    mutationFn: (id: string) => fetcher(`/riders/${id}/restrict`, { method: "POST", body: "{}" }),
./src/hooks/use-admin.ts:    mutationFn: (id: string) => fetcher(`/riders/${id}/unrestrict`, { method: "POST", body: "{}" }),
./src/hooks/use-admin.ts:  useQuery({ queryKey: ["admin-promo-codes"], queryFn: () => fetcher("/promo-codes"), refetchInterval: REFETCH_INTERVAL });
./src/hooks/use-admin.ts:    mutationFn: (data: any) => fetcher("/promo-codes", { method: "POST", body: JSON.stringify(data) }),
./src/hooks/use-admin.ts:    mutationFn: ({ id, ...data }: any) => fetcher(`/promo-codes/${id}`, { method: "PATCH", body: JSON.stringify(data) }),
./src/hooks/use-admin.ts:    mutationFn: (id: string) => fetcher(`/promo-codes/${id}`, { method: "DELETE" }),
./src/hooks/use-admin.ts:    queryFn: () => fetcher(`/deposit-requests${status ? `?status=${status}` : ""}`),
./src/hooks/use-admin.ts:    refetchInterval: REFETCH_INTERVAL,
./src/hooks/use-admin.ts:      fetcher(`/deposit-requests/${id}/approve`, { method: "PATCH", body: JSON.stringify({ refNo, note }) }),
./src/hooks/use-admin.ts:      fetcher(`/deposit-requests/${id}/reject`, { method: "PATCH", body: JSON.stringify({ reason }) }),
./src/hooks/use-admin.ts:      fetcher("/deposit-requests/bulk-approve", { method: "POST", body: JSON.stringify({ ids, refNo }) }),
./src/hooks/use-admin.ts:      fetcher("/deposit-requests/bulk-reject", { method: "POST", body: JSON.stringify({ ids, reason }) }),
./src/hooks/use-admin.ts:    queryFn: () => fetcher(`/withdrawal-requests${status ? `?status=${status}` : ""}`),
./src/hooks/use-admin.ts:    refetchInterval: REFETCH_INTERVAL,
./src/hooks/use-admin.ts:      fetcher(`/withdrawal-requests/${id}/approve`, { method: "PATCH", body: JSON.stringify({ refNo, note }) }),
./src/hooks/use-admin.ts:      fetcher(`/withdrawal-requests/${id}/reject`, { method: "PATCH", body: JSON.stringify({ reason }) }),
./src/hooks/use-admin.ts:      fetcher("/withdrawal-requests/batch-approve", { method: "PATCH", body: JSON.stringify({ ids }) }),
./src/hooks/use-admin.ts:      fetcher("/withdrawal-requests/batch-reject", { method: "PATCH", body: JSON.stringify({ ids, reason }) }),
./src/hooks/use-admin.ts:      fetcher(`/riders/${id}/credit`, { method: "POST", body: JSON.stringify({ amount, description, type }) }),
./src/hooks/use-admin.ts:  useQuery({ queryKey: ["admin-ride-services"], queryFn: () => fetcher("/ride-services"), staleTime: 0 });
./src/hooks/use-admin.ts:      fetcher("/ride-services", { method: "POST", body: JSON.stringify(data) }),
./src/hooks/use-admin.ts:      fetcher(`/ride-services/${id}`, { method: "PATCH", body: JSON.stringify(data) }),
./src/hooks/use-admin.ts:    mutationFn: (id: string) => fetcher(`/ride-services/${id}`, { method: "DELETE" }),
./src/hooks/use-admin.ts:    queryFn: () => fetcher(`/all-notifications${role ? `?role=${role}` : ""}`),
./src/hooks/use-admin.ts:    refetchInterval: REFETCH_INTERVAL,
./src/hooks/use-admin.ts:    queryFn: () => fetcher("/locations"),
./src/hooks/use-admin.ts:    refetchInterval: REFETCH_INTERVAL,
./src/hooks/use-admin.ts:      fetcher("/locations", { method: "POST", body: JSON.stringify(data) }),
./src/hooks/use-admin.ts:      fetcher(`/locations/${id}`, { method: "PATCH", body: JSON.stringify(data) }),
./src/hooks/use-admin.ts:    mutationFn: (id: string) => fetcher(`/locations/${id}`, { method: "DELETE" }),
./src/hooks/use-admin.ts:    queryFn: () => fetcher("/school-routes"),
./src/hooks/use-admin.ts:    refetchInterval: REFETCH_INTERVAL,
./src/hooks/use-admin.ts:      fetcher("/school-routes", { method: "POST", body: JSON.stringify(data) }),
./src/hooks/use-admin.ts:      fetcher(`/school-routes/${id}`, { method: "PATCH", body: JSON.stringify(data) }),
./src/hooks/use-admin.ts:    mutationFn: (id: string) => fetcher(`/school-routes/${id}`, { method: "DELETE" }),
./src/hooks/use-admin.ts:    queryFn: () => fetcher(`/school-subscriptions${routeId ? `?routeId=${routeId}` : ""}`),
./src/hooks/use-admin.ts:    refetchInterval: REFETCH_INTERVAL,
./src/hooks/use-admin.ts:    queryFn: () => fetcher("/live-riders"),
./src/hooks/use-admin.ts:    refetchInterval: 10_000,
./src/hooks/use-admin.ts:    queryFn: () => fetcher("/customer-locations"),
./src/hooks/use-admin.ts:    refetchInterval: 30_000,
./src/hooks/use-admin.ts:      fetcher(`/users/${id}/request-correction`, { method: "PATCH", body: JSON.stringify({ field, note }) }),
./src/hooks/use-admin.ts:      fetcher("/users/bulk-ban", { method: "PATCH", body: JSON.stringify({ ids, action, reason }) }),
./src/hooks/use-admin.ts:      fetcher(`/orders/${orderId}/assign-rider`, { method: "PATCH", body: JSON.stringify({ riderId, riderName, riderPhone }) }),
./src/hooks/use-admin.ts:      fetcher(`/vendors/${id}/commission`, { method: "PATCH", body: JSON.stringify({ commissionPct }) }),
./src/hooks/use-admin.ts:      fetcher(`/riders/${id}/online`, { method: "PATCH", body: JSON.stringify({ isOnline }) }),
./src/hooks/use-admin.ts:  useQuery({ queryKey: ["admin-revenue-trend"], queryFn: () => fetcher("/revenue-trend"), refetchInterval: 60_000 });
./src/hooks/use-admin.ts:  useQuery({ queryKey: ["admin-leaderboard"], queryFn: () => fetcher("/leaderboard"), refetchInterval: 60_000 });
./src/hooks/use-admin.ts:      fetcher(`/rides/${id}/cancel`, { method: "POST", body: JSON.stringify({ reason }) }),
./src/hooks/use-admin.ts:      fetcher(`/rides/${id}/refund`, { method: "POST", body: JSON.stringify({ amount, reason }) }),
./src/hooks/use-admin.ts:      fetcher(`/rides/${id}/reassign`, { method: "POST", body: JSON.stringify({ riderId, riderName, riderPhone }) }),
./src/hooks/use-admin.ts:    queryFn: () => fetcher(`/rides/${rideId}/detail`),
./src/hooks/use-admin.ts:    queryFn: () => fetcher(`/rides/${rideId}/audit-trail`),
./src/hooks/use-admin.ts:    refetchInterval: 15_000,
./src/hooks/use-admin.ts:    queryFn: () => fetcher("/dispatch-monitor"),
./src/hooks/use-admin.ts:    refetchInterval: 10_000,
./src/hooks/use-admin.ts:    queryFn: () => fetcher(`/audit-log${q ? `?${q}` : ""}`),
./src/hooks/use-admin.ts:    refetchInterval: 30_000,
./src/hooks/use-admin.ts:    queryFn: () => fetcher(`/riders/${userId}/route${qs}`),
./src/hooks/use-admin.ts:    refetchOnWindowFocus: false,
./src/hooks/use-admin.ts:      queryFn: () => fetcher(`/riders/${id}/route?sinceOnline=true`),
./src/hooks/use-admin.ts:      refetchOnWindowFocus: false,
./src/hooks/use-admin.ts:      return fetcher(`/reviews${query ? `?${query}` : ""}`);
./src/hooks/use-admin.ts:    refetchInterval: 30_000,
./src/hooks/use-admin.ts:    queryFn: () => fetcher("/reviews/moderation-queue"),
./src/hooks/use-admin.ts:    refetchInterval: 15_000,
./src/hooks/use-admin.ts:    mutationFn: (id: string) => fetcher(`/reviews/${id}/approve`, { method: "PATCH" }),
./src/hooks/use-admin.ts:    mutationFn: (id: string) => fetcher(`/reviews/${id}/reject`, { method: "PATCH" }),
./src/hooks/use-admin.ts:  useMutation({ mutationFn: () => fetcher("/jobs/rating-suspension", { method: "POST" }) });
./src/hooks/use-admin.ts:    mutationFn: (id: string) => fetcher(`/${role}/${id}/override-suspension`, { method: "POST" }),
./src/hooks/use-admin.ts:    queryFn: () => fetcher("/service-zones"),
./src/hooks/use-admin.ts:      fetcher("/service-zones", { method: "POST", body: JSON.stringify(data) }),
./src/hooks/use-admin.ts:      fetcher(`/service-zones/${id}`, { method: "PUT", body: JSON.stringify(data) }),
./src/hooks/use-admin.ts:      fetcher(`/service-zones/${id}`, { method: "DELETE" }),
./src/hooks/use-admin.ts:    queryFn: () => fetcher("/delivery-access"),
./src/hooks/use-admin.ts:    refetchInterval: REFETCH_INTERVAL,
./src/hooks/use-admin.ts:      fetcher("/delivery-access/mode", { method: "PUT", body: JSON.stringify({ mode }) }),
./src/hooks/use-admin.ts:      fetcher("/delivery-access/whitelist", { method: "POST", body: JSON.stringify(data) }),
./src/hooks/use-admin.ts:      fetcher("/delivery-access/whitelist/bulk", { method: "POST", body: JSON.stringify({ entries }) }),
./src/hooks/use-admin.ts:      fetcher(`/delivery-access/whitelist/${id}`, { method: "PATCH", body: JSON.stringify(data) }),
./src/hooks/use-admin.ts:      fetcher(`/delivery-access/whitelist/${id}`, { method: "DELETE" }),
./src/hooks/use-admin.ts:    queryFn: () => fetcher("/delivery-access/requests"),
./src/hooks/use-admin.ts:    refetchInterval: REFETCH_INTERVAL,
./src/hooks/use-admin.ts:      fetcher(`/delivery-access/requests/${id}`, { method: "PATCH", body: JSON.stringify({ status, notes }) }),
./src/hooks/use-admin.ts:    queryFn: () => fetcher("/delivery-access/audit"),
./src/hooks/use-admin.ts:    queryFn: () => fetcher(`/conditions${params ? `?${params}` : ""}`),
./src/hooks/use-admin.ts:    refetchInterval: REFETCH_INTERVAL,
./src/hooks/use-admin.ts:    queryFn: () => fetcher(`/conditions/user/${userId}`),
./src/hooks/use-admin.ts:      fetcher("/conditions", { method: "POST", body: JSON.stringify(data) }),
./src/hooks/use-admin.ts:      fetcher(`/conditions/${id}`, { method: "PATCH", body: JSON.stringify(data) }),
./src/hooks/use-admin.ts:      fetcher(`/conditions/${id}`, { method: "DELETE" }),
./src/hooks/use-admin.ts:      fetcher("/conditions/bulk", { method: "POST", body: JSON.stringify(data) }),
./src/hooks/use-admin.ts:    queryFn: () => fetcher("/condition-rules"),
./src/hooks/use-admin.ts:      fetcher("/condition-rules", { method: "POST", body: JSON.stringify(data) }),
./src/hooks/use-admin.ts:      fetcher(`/condition-rules/${id}`, { method: "PATCH", body: JSON.stringify(data) }),
./src/hooks/use-admin.ts:      fetcher(`/condition-rules/${id}`, { method: "DELETE" }),
./src/hooks/use-admin.ts:      fetcher("/condition-rules/seed-defaults", { method: "POST", body: "{}" }),
./src/hooks/use-admin.ts:    queryFn: () => fetcher("/condition-settings"),
./src/hooks/use-admin.ts:      fetcher("/condition-settings", { method: "PATCH", body: JSON.stringify(data) }),
./src/hooks/use-admin.ts:      fetcher(`/condition-rules/evaluate/${userId}`, { method: "POST" }),
./src/hooks/use-admin.ts:  useQuery({ queryKey: ["admin-sms-gateways"], queryFn: () => fetcher("/sms-gateways"), refetchInterval: 60_000 });
./src/hooks/use-admin.ts:    mutationFn: (data: any) => fetcher("/sms-gateways", { method: "POST", body: JSON.stringify(data) }),
./src/hooks/use-admin.ts:    mutationFn: ({ id, ...data }: any) => fetcher(`/sms-gateways/${id}`, { method: "PATCH", body: JSON.stringify(data) }),
./src/hooks/use-admin.ts:    mutationFn: (id: string) => fetcher(`/sms-gateways/${id}`, { method: "DELETE" }),
./src/hooks/use-admin.ts:    mutationFn: (id: string) => fetcher(`/sms-gateways/${id}/toggle`, { method: "PATCH" }),
./src/hooks/use-admin.ts:  useQuery({ queryKey: ["admin-otp-whitelist"], queryFn: () => fetcher("/whitelist"), refetchInterval: 30_000 });
./src/hooks/use-admin.ts:      fetcher("/whitelist", { method: "POST", body: JSON.stringify(data) }),
./src/hooks/use-admin.ts:    mutationFn: ({ id, ...data }: any) => fetcher(`/whitelist/${id}`, { method: "PATCH", body: JSON.stringify(data) }),
./src/hooks/use-admin.ts:    mutationFn: (id: string) => fetcher(`/whitelist/${id}`, { method: "DELETE" }),
./src/hooks/use-admin.ts:    queryFn: () => fetcher(`/users/${userId}/sessions`),
./src/hooks/use-admin.ts:      fetcher(`/users/${userId}/sessions/${sessionId}`, { method: "DELETE" }),
./src/hooks/use-admin.ts:    mutationFn: (userId: string) => fetcher(`/users/${userId}/sessions`, { method: "DELETE" }),
./src/pages/sos-alerts.tsx:import { fetcher } from "@/lib/api";
./src/pages/sos-alerts.tsx:      await fetcher(`/sos/alerts/${alert.id}/resolve`, {
./src/pages/sos-alerts.tsx:      const data = await fetcher(`/sos/alerts${qs}`);
./src/pages/sos-alerts.tsx:      await fetcher(`/sos/alerts/${id}/acknowledge`, { method: "PATCH", body: "{}" });
./src/pages/settings.tsx:import { fetcher } from "@/lib/api";
./src/pages/settings.tsx:      const data = await fetcher("/platform-settings");
./src/pages/settings.tsx:      await fetcher("/platform-settings", { method: "PUT", body: JSON.stringify({ settings: changed }) });
./src/pages/settings.tsx:      const data = await fetcher("/platform-settings/backup");
./src/pages/settings.tsx:      const result = await fetcher("/platform-settings/restore", { method: "POST", body: JSON.stringify({ settings: payload }) });
./src/pages/faq-management.tsx:  const res = await fetch(`${API_BASE}${path}`, { ...opts, headers: { ...adminHeaders(), ...(opts.headers as Record<string, string> || {}) } });
./src/pages/faq-management.tsx:  const { data, isLoading, refetch } = useQuery<{ faqs: FAQ[]; total: number }>({
./src/pages/faq-management.tsx:          <Button variant="outline" size="sm" onClick={() => refetch()} className="h-8 rounded-xl gap-1">
./src/pages/popups.tsx:import { fetcher } from "@/lib/api";
./src/pages/popups.tsx:    queryFn: () => fetcher("/popups"),
./src/pages/popups.tsx:    refetchInterval: 30000,
./src/pages/popups.tsx:    queryFn: () => fetcher("/popups/templates"),
./src/pages/popups.tsx:    queryFn: () => fetcher(`/popups/${analyticsId}/analytics`),
./src/pages/popups.tsx:      if (editingId) return fetcher(`/popups/${editingId}`, { method: "PATCH", body: JSON.stringify(body) });
./src/pages/popups.tsx:      return fetcher("/popups", { method: "POST", body: JSON.stringify(body) });
./src/pages/popups.tsx:    mutationFn: (id: string) => fetcher(`/popups/${id}`, { method: "DELETE" }),
./src/pages/popups.tsx:      fetcher(`/popups/${id}`, { method: "PATCH", body: JSON.stringify({ status }) }),
./src/pages/popups.tsx:    mutationFn: (id: string) => fetcher(`/popups/clone/${id}`, { method: "POST", body: "{}" }),
./src/pages/popups.tsx:      if (editingTplId) return fetcher(`/popups/templates/${editingTplId}`, { method: "PATCH", body: JSON.stringify(body) });
./src/pages/popups.tsx:      return fetcher("/popups/templates", { method: "POST", body: JSON.stringify(body) });
./src/pages/popups.tsx:    mutationFn: (id: string) => fetcher(`/popups/templates/${id}`, { method: "DELETE" }),
./src/pages/popups.tsx:      const result = await fetcher("/popups/ai-generate", { method: "POST", body: JSON.stringify({ goal: aiGoal }) });
./src/pages/dashboard.tsx:import { fetcher } from "@/lib/api";
./src/pages/dashboard.tsx:  fetcher("/dashboard-export").then((data: any) => {
./src/pages/settings-system.tsx:    const res = await fetch(`/api/admin/system${path}`, {
./src/pages/settings-system.tsx:      const res = await fetch("/api/admin/system/backup", { headers: { "x-admin-token": adminSecret } });
./src/pages/settings-system.tsx:      const res = await fetch(endpoint, {
./src/pages/settings-system.tsx:      const res = await fetch(`/api/admin/system/export/${endpoint}${qs}`, { headers: { "x-admin-token": adminSecret } });
./src/pages/promotions-hub.tsx:import { fetcher } from "@/lib/api";
./src/pages/promotions-hub.tsx:      ? fetcher(`/promotions/campaigns/${campaign!.id}`, { method: "PATCH", body: JSON.stringify(body) })
./src/pages/promotions-hub.tsx:      : fetcher("/promotions/campaigns", { method: "POST", body: JSON.stringify(body) }),
./src/pages/promotions-hub.tsx:      ? fetcher(`/promotions/offers/${offer!.id}`, { method: "PATCH", body: JSON.stringify(body) })
./src/pages/promotions-hub.tsx:      : fetcher("/promotions/offers", { method: "POST", body: JSON.stringify(body) }),
./src/pages/promotions-hub.tsx:    queryFn: () => fetcher("/promotions/ai-recommendations"),
./src/pages/promotions-hub.tsx:    queryFn: () => fetcher("/promotions/analytics"),
./src/pages/promotions-hub.tsx:  const { data: campaignsData, isLoading: campaignsLoading, refetch: refetchCampaigns } = useQuery({
./src/pages/promotions-hub.tsx:    queryFn: () => fetcher("/promotions/campaigns"),
./src/pages/promotions-hub.tsx:    refetchInterval: 30000,
./src/pages/promotions-hub.tsx:  const { data: offersData, isLoading: offersLoading, refetch: refetchOffers } = useQuery({
./src/pages/promotions-hub.tsx:    queryFn: () => fetcher("/promotions/offers"),
./src/pages/promotions-hub.tsx:    refetchInterval: 30000,
./src/pages/promotions-hub.tsx:    queryFn: () => fetcher("/promotions/offers/pending"),
./src/pages/promotions-hub.tsx:    refetchInterval: 30000,
./src/pages/promotions-hub.tsx:    mutationFn: (id: string) => fetcher(`/promotions/campaigns/${id}`, { method: "DELETE" }),
./src/pages/promotions-hub.tsx:    mutationFn: (id: string) => fetcher(`/promotions/offers/${id}`, { method: "DELETE" }),
./src/pages/promotions-hub.tsx:    mutationFn: (id: string) => fetcher(`/promotions/offers/${id}/clone`, { method: "POST" }),
./src/pages/promotions-hub.tsx:    mutationFn: (id: string) => fetcher(`/promotions/offers/${id}/approve`, { method: "POST" }),
./src/pages/promotions-hub.tsx:      fetcher(`/promotions/offers/${id}/reject`, { method: "POST", body: JSON.stringify({ reason }) }),
./src/pages/promotions-hub.tsx:    mutationFn: (id: string) => fetcher(`/promotions/offers/${id}/submit`, { method: "POST" }),
./src/pages/promotions-hub.tsx:      fetcher("/promotions/offers/bulk", { method: "POST", body: JSON.stringify({ ids, action }) }),
./src/pages/promotions-hub.tsx:          <Button variant="outline" size="sm" onClick={() => { refetchCampaigns(); refetchOffers(); }} className="h-9 rounded-xl gap-2">
./src/pages/communication.tsx:import { fetcher, fetcherWithMeta } from "@/lib/api";
./src/pages/communication.tsx:    fetcher("/communication/dashboard").then(setStats).catch(() => {});
./src/pages/communication.tsx:    fetcher("/communication/settings").then((d: Record<string, string>) => {
./src/pages/communication.tsx:      await fetcher("/communication/settings", { method: "PUT", body: JSON.stringify(merged) });
./src/pages/communication.tsx:    fetcherWithMeta(`/communication/conversations?search=${encodeURIComponent(debouncedSearch)}&page=${page}&limit=${LIMIT}`)
./src/pages/communication.tsx:      const resp = await fetcherWithMeta(`/communication/conversations/${conv.id}/messages`);
./src/pages/communication.tsx:    fetcherWithMeta(`/communication/calls?page=${page}&limit=${LIMIT}`)
./src/pages/communication.tsx:    fetcherWithMeta(`/communication/ai-logs?page=${page}&limit=${LIMIT}`)
./src/pages/communication.tsx:    fetcher(`/communication/flags?status=${status}`)
./src/pages/communication.tsx:      await fetcher(`/communication/flags/${id}/resolve`, { method: "PATCH" });
./src/pages/communication.tsx:      const result = await fetcher("/communication/roles/ai-generate", { method: "POST", body: JSON.stringify({ description: aiDescription }) });
./src/pages/communication.tsx:        await fetcher(`/communication/roles/${editId}`, { method: "PUT", body: JSON.stringify(form) });
./src/pages/communication.tsx:        await fetcher("/communication/roles", { method: "POST", body: JSON.stringify(form) });
./src/pages/communication.tsx:    fetcher("/communication/roles")
./src/pages/communication.tsx:      await fetcher(`/communication/roles/${id}`, { method: "DELETE" });
./src/pages/communication.tsx:    fetcherWithMeta(`/communication/ajk-ids?${params.toString()}`)
./src/pages/communication.tsx:      const data = await fetcher(`/communication/users/search?q=${encodeURIComponent(q)}`);
./src/pages/communication.tsx:      await fetcher(`/communication/ajk-ids/${editUser.id}`, {
./src/pages/communication.tsx:      await fetcher(`/communication/users/${user.id}/${action}`, { method: "POST" });
./src/pages/riders.tsx:  const { data, isLoading, refetch, isFetching } = useRiders();
./src/pages/riders.tsx:      onSuccess: () => { toast({ title: "Rider approved ✅" }); refetch(); },
./src/pages/riders.tsx:      onSuccess: () => { toast({ title: "Rider rejected" }); refetch(); },
./src/pages/riders.tsx:          <Button variant="outline" size="sm" onClick={() => refetch()} disabled={isFetching} className="h-9 rounded-xl gap-2">
./src/pages/loyalty.tsx:import { fetcher } from "@/lib/api";
./src/pages/loyalty.tsx:    queryFn: () => fetcher(`/loyalty/users${search ? `?q=${encodeURIComponent(search)}` : ""}`),
./src/pages/loyalty.tsx:    refetchInterval: 30_000,
./src/pages/loyalty.tsx:      fetcher(`/loyalty/users/${user.id}/adjust`, { method: "POST", body: JSON.stringify(body) }),
./src/pages/loyalty.tsx:  const { data, isLoading, refetch } = useLoyaltyUsers(debouncedSearch);
./src/pages/loyalty.tsx:    <PullToRefresh onRefresh={async () => { await refetch(); }}>
./src/pages/experiments.tsx:import { fetcher } from "@/lib/api";
./src/pages/experiments.tsx:  const { data, isLoading, refetch } = useQuery({
./src/pages/experiments.tsx:    queryFn: () => fetcher("/experiments"),
./src/pages/experiments.tsx:    refetchInterval: 30_000,
./src/pages/experiments.tsx:    queryFn: () => fetcher(`/experiments/${showResults}/results`),
./src/pages/experiments.tsx:    mutationFn: (body: any) => fetcher("/experiments", { method: "POST", body: JSON.stringify(body) }),
./src/pages/experiments.tsx:      fetcher(`/experiments/${id}/status`, { method: "PATCH", body: JSON.stringify({ status }) }),
./src/pages/experiments.tsx:    mutationFn: (id: string) => fetcher(`/experiments/${id}`, { method: "DELETE" }),
./src/pages/experiments.tsx:    <PullToRefresh onRefresh={async () => { await refetch(); }}>
./src/pages/notifications.tsx:  const { data: nData, isLoading, refetch } = useAllNotifications(roleFilter || undefined);
./src/pages/notifications.tsx:        <Button variant="outline" size="sm" onClick={() => refetch()} className="self-start sm:self-auto">
./src/pages/settings-weather.tsx:import { fetcher } from "@/lib/api";
./src/pages/settings-weather.tsx:    queryFn: () => fetcher("/weather-config"),
./src/pages/settings-weather.tsx:      fetcher("/weather-config", { method: "PATCH", body: JSON.stringify(body) }),
./src/pages/orders/GpsStampCard.tsx:    fetch(`https://nominatim.openstreetmap.org/reverse?lat=${cLat}&lon=${cLng}&format=json&zoom=16&addressdetails=1`, {
./src/pages/orders/index.tsx:import { useOrdersEnriched, useOrdersStats, fetchOrdersExport, useUpdateOrder, useAssignRider, useRiders, useOrderRefund } from "@/hooks/use-admin";
./src/pages/orders/index.tsx:      const result = await fetchOrdersExport({
./src/pages/search-analytics.tsx:  const res = await fetch(`${API_BASE}${path}`, { headers: adminHeaders() });
./src/pages/search-analytics.tsx:  const { data: trendingData, isLoading: trendLoading, refetch: refetchTrending } = useQuery<{ products: TrendingProduct[] }>({
./src/pages/search-analytics.tsx:      const res = await fetch(`${API_BASE}/admin/users?limit=1`, { headers: adminHeaders() });
./src/pages/search-analytics.tsx:          onClick={() => { refetchTrending(); }}
./src/pages/Withdrawals.tsx:  const { data, isLoading, refetch } = useWithdrawalRequests();
./src/pages/Withdrawals.tsx:        <Button variant="outline" size="sm" onClick={() => refetch()} className="self-start sm:self-auto">
./src/pages/account-conditions.tsx:  const { data, isLoading, refetch, isFetching } = useConditions(filters);
./src/pages/account-conditions.tsx:          <Button variant="outline" size="sm" onClick={() => refetch()} disabled={isFetching} className="h-9 rounded-xl gap-2">
./src/pages/deep-links.tsx:import { fetcher } from "@/lib/api";
./src/pages/deep-links.tsx:  const { data, isLoading, refetch } = useQuery({
./src/pages/deep-links.tsx:    queryFn: () => fetcher("/deep-links"),
./src/pages/deep-links.tsx:    refetchInterval: 30_000,
./src/pages/deep-links.tsx:    mutationFn: (body: any) => fetcher("/deep-links", { method: "POST", body: JSON.stringify(body) }),
./src/pages/deep-links.tsx:    mutationFn: (id: string) => fetcher(`/deep-links/${id}`, { method: "DELETE" }),
./src/pages/deep-links.tsx:    <PullToRefresh onRefresh={async () => { await refetch(); }}>
./src/pages/promo-codes.tsx:  const { data, isLoading, refetch, isFetching } = usePromoCodes();
./src/pages/promo-codes.tsx:          <Button variant="outline" size="sm" onClick={() => refetch()} disabled={isFetching} className="h-9 rounded-xl gap-2">
./src/pages/vendors.tsx:  const { data, isLoading, refetch, isFetching } = useVendors();
./src/pages/vendors.tsx:          <Button variant="outline" size="sm" onClick={() => refetch()} disabled={isFetching} className="h-9 rounded-xl gap-2">
./src/pages/condition-rules.tsx:  const { data: rulesData, isLoading: rulesLoading, refetch } = useConditionRules();
./src/pages/condition-rules.tsx:          <Button variant="outline" size="sm" onClick={() => refetch()} className="h-9 rounded-xl gap-2">
./src/pages/qr-codes.tsx:import { fetcher } from "@/lib/api";
./src/pages/qr-codes.tsx:    queryFn: () => fetcher("/qr-codes"),
./src/pages/qr-codes.tsx:    refetchInterval: 30_000,
./src/pages/qr-codes.tsx:  const { data, isLoading, refetch } = useQrCodes();
./src/pages/qr-codes.tsx:    mutationFn: (body: { label: string; type: string }) => fetcher("/qr-codes", { method: "POST", body: JSON.stringify(body) }),
./src/pages/qr-codes.tsx:      fetcher(`/qr-codes/${id}/${activate ? "activate" : "deactivate"}`, { method: "PATCH", body: "{}" }),
./src/pages/qr-codes.tsx:    <PullToRefresh onRefresh={async () => { await refetch(); }}>
./src/pages/reviews.tsx:import { fetcher, getApiBase, getToken } from "@/lib/api";
./src/pages/reviews.tsx:      const data = await fetcher("/reviews/import", { method: "POST", body: JSON.stringify({ csvData: csvText }) });
./src/pages/reviews.tsx:  const { data, isLoading, refetch } = useQuery({
./src/pages/reviews.tsx:    queryFn: () => fetcher(`/reviews?${buildQS()}`),
./src/pages/reviews.tsx:    mutationFn: (id: string) => fetcher(`/reviews/${id}/hide`, { method: "PATCH" }),
./src/pages/reviews.tsx:    mutationFn: (id: string) => fetcher(`/reviews/${id}`, { method: "DELETE" }),
./src/pages/reviews.tsx:    mutationFn: (id: string) => fetcher(`/ride-ratings/${id}/hide`, { method: "PATCH" }),
./src/pages/reviews.tsx:    mutationFn: (id: string) => fetcher(`/ride-ratings/${id}`, { method: "DELETE" }),
./src/pages/reviews.tsx:      ...toHide.map(r => fetcher(`/reviews/${r.id}/hide`, { method: "PATCH" })),
./src/pages/reviews.tsx:      ...toHideR.map(r => fetcher(`/ride-ratings/${r.id}/hide`, { method: "PATCH" })),
./src/pages/reviews.tsx:      ...orders.map(r => fetcher(`/reviews/${r.id}`, { method: "DELETE" })),
./src/pages/reviews.tsx:      ...rides.map(r => fetcher(`/ride-ratings/${r.id}`, { method: "DELETE" })),
./src/pages/reviews.tsx:    const res = await fetch(url, { headers: token ? { "x-admin-token": token } : {} });
./src/pages/reviews.tsx:            <Button variant="outline" size="sm" onClick={() => refetch()}>
./src/pages/reviews.tsx:      {showImport && <ImportModal onClose={() => setShowImport(false)} onSuccess={() => refetch()} />}
./src/pages/reviews.tsx:  const { data, isLoading, refetch } = useQuery({
./src/pages/reviews.tsx:    queryFn: () => fetcher("/vendor-ratings"),
./src/pages/reviews.tsx:        <Button variant="outline" size="sm" onClick={() => refetch()}>
./src/pages/wishlist-insights.tsx:import { fetcher } from "@/lib/api";
./src/pages/wishlist-insights.tsx:    queryFn: () => fetcher("/wishlist-analytics"),
./src/pages/wishlist-insights.tsx:    refetchInterval: 60_000,
./src/pages/wishlist-insights.tsx:  const { data, isLoading, refetch } = useWishlistAnalytics();
./src/pages/wishlist-insights.tsx:    <PullToRefresh onRefresh={async () => { await refetch(); }}>
./src/pages/error-monitor.tsx:import { fetcher } from "@/lib/api";
./src/pages/error-monitor.tsx:    queryFn: () => fetcher(`/error-reports?${p}`),
./src/pages/error-monitor.tsx:    refetchInterval: 15000,
./src/pages/error-monitor.tsx:  const { data, isLoading, refetch } = useQuery({
./src/pages/error-monitor.tsx:    queryFn: () => activeTab === "customers" ? Promise.resolve(null) : fetcher(`/error-reports?${params}`),
./src/pages/error-monitor.tsx:    refetchInterval: 30000,
./src/pages/error-monitor.tsx:  const { data: customerData, isLoading: customerLoading, refetch: refetchCustomers } = useQuery({
./src/pages/error-monitor.tsx:    queryFn: () => fetcher(`/error-reports/customer-reports?${customerParams}`),
./src/pages/error-monitor.tsx:    refetchInterval: 30000,
./src/pages/error-monitor.tsx:    queryFn: () => fetcher("/error-reports/customer-reports?status=new&limit=1"),
./src/pages/error-monitor.tsx:    refetchInterval: 30000,
./src/pages/error-monitor.tsx:      fetcher(`/error-reports/${id}`, { method: "PATCH", body: JSON.stringify({ status: newStatus }) }),
./src/pages/error-monitor.tsx:      fetcher(`/error-reports/customer-reports/${id}`, {
./src/pages/error-monitor.tsx:      fetcher(`/error-reports/${id}/resolve`, {
./src/pages/error-monitor.tsx:      fetcher(`/error-reports/${id}/undo`, { method: "POST" }),
./src/pages/error-monitor.tsx:  const { data: autoResolveSettings, refetch: refetchAutoSettings } = useQuery<AutoResolveSettings>({
./src/pages/error-monitor.tsx:    queryFn: () => fetcher("/error-reports/auto-resolve-settings"),
./src/pages/error-monitor.tsx:    refetchInterval: 60000,
./src/pages/error-monitor.tsx:      fetcher("/error-reports/auto-resolve-settings", {
./src/pages/error-monitor.tsx:      refetchAutoSettings();
./src/pages/error-monitor.tsx:  const { data: autoResolveLog, refetch: refetchAutoLog } = useQuery<AutoResolveLogEntry[]>({
./src/pages/error-monitor.tsx:    queryFn: () => fetcher("/error-reports/auto-resolve-log?limit=50"),
./src/pages/error-monitor.tsx:    refetchInterval: 30000,
./src/pages/error-monitor.tsx:    mutationFn: () => fetcher("/error-reports/auto-resolve-run", { method: "POST" }),
./src/pages/error-monitor.tsx:      refetchAutoLog();
./src/pages/error-monitor.tsx:      const result = await fetcher(`/error-reports/${id}/generate-task`, { method: "POST" });
./src/pages/error-monitor.tsx:      const result = await fetcher("/error-reports/scan", { method: "POST" });
./src/pages/error-monitor.tsx:      await fetcher("/error-reports/bulk-resolve", {
./src/pages/error-monitor.tsx:            onClick={() => activeTab === "customers" ? refetchCustomers() : refetch()}
./src/pages/users.tsx:import { fetcher } from "@/lib/api";
./src/pages/users.tsx:    mutationFn: (body: any) => fetcher(`/users/${user.id}/security`, { method: "PATCH", body: JSON.stringify(body) }),
./src/pages/users.tsx:    mutationFn: () => fetcher(`/users/${user.id}/reset-otp`, { method: "POST", body: "{}" }),
./src/pages/users.tsx:    mutationFn: (minutes: number) => fetcher(`/users/${user.id}/otp/bypass`, { method: "POST", body: JSON.stringify({ minutes }) }),
./src/pages/users.tsx:    mutationFn: () => fetcher(`/users/${user.id}/otp/bypass`, { method: "DELETE", body: "{}" }),
./src/pages/users.tsx:    mutationFn: () => fetcher(`/users/${user.id}/2fa/disable`, { method: "POST", body: "{}" }),
./src/pages/users.tsx:    mutationFn: () => fetcher(`/users/${user.id}/reset-wallet-pin`, { method: "POST", body: "{}" }),
./src/pages/users.tsx:    mutationFn: (body: any) => fetcher(`/users/${user.id}/identity`, { method: "PATCH", body: JSON.stringify(body) }),
./src/pages/users.tsx:    queryFn: () => fetcher(`/users/${user.id}/addresses`),
./src/pages/users.tsx:  const { data, isLoading, refetch, isFetching, isError } = useUsers(conditionTier !== "all" ? conditionTier : undefined);
./src/pages/users.tsx:  const { data: pendingData, refetch: refetchPending } = usePendingUsers();
./src/pages/users.tsx:    mutationFn: (userId: string) => fetcher(`/admin/users/${userId}/waive-debt`, { method: "PATCH" }),
./src/pages/users.tsx:            onClick={() => refetch()}
./src/pages/users.tsx:            <Button variant="ghost" size="sm" onClick={() => refetchPending()} className="h-7 text-xs text-amber-700 hover:bg-amber-100">
./src/pages/users.tsx:              <Button variant="outline" size="sm" onClick={() => refetch()} className="rounded-xl border-red-200 text-red-700 hover:bg-red-100">
./src/pages/flash-deals.tsx:import { fetcher } from "@/lib/api";
./src/pages/flash-deals.tsx:    queryFn: () => fetcher("/flash-deals"),
./src/pages/flash-deals.tsx:    refetchInterval: 30000,
./src/pages/flash-deals.tsx:    queryFn: () => fetcher("/products"),
./src/pages/flash-deals.tsx:      if (editingDeal) return fetcher(`/flash-deals/${editingDeal.id}`, { method: "PATCH", body: JSON.stringify(body) });
./src/pages/flash-deals.tsx:      return fetcher("/flash-deals", { method: "POST", body: JSON.stringify(body) });
./src/pages/flash-deals.tsx:    mutationFn: (id: string) => fetcher(`/flash-deals/${id}`, { method: "DELETE" }),
./src/pages/flash-deals.tsx:      fetcher(`/flash-deals/${id}`, { method: "PATCH", body: JSON.stringify({ isActive }) }),
./src/pages/otp-control.tsx:import { fetcher, getApiBase, getToken } from "@/lib/api";
./src/pages/otp-control.tsx:  const r = await fetch(`${getApiBase()}${path}`, {
./src/pages/otp-control.tsx:      const d = await fetcher(`/users/search?q=${encodeURIComponent(query)}&limit=20`);
./src/pages/otp-control.tsx:  const { data, isLoading, refetch } = useOtpWhitelist();
./src/pages/otp-control.tsx:      <Button size="sm" variant="ghost" className="mt-3 text-xs" onClick={() => refetch()}>
./src/pages/sms-gateways.tsx:  const { data, isLoading, refetch } = useSmsGateways();
./src/pages/sms-gateways.tsx:          <Button variant="outline" size="sm" onClick={() => refetch()} className="rounded-xl gap-1.5"><RefreshCw className="w-3.5 h-3.5" /> Refresh</Button>
./src/pages/support-chat.tsx:  const res = await fetch(`${API_BASE}${path}`, { ...opts, headers: { ...adminHeaders(), ...(opts.headers as Record<string, string> || {}) } });
./src/pages/support-chat.tsx:  const { data: convsData, isLoading: convsLoading, refetch: refetchConvs } = useQuery({
./src/pages/support-chat.tsx:    refetchInterval: 15000,
./src/pages/support-chat.tsx:    refetchInterval: false,
./src/pages/support-chat.tsx:      const res = await fetch(`${API_BASE}/admin/support-chat/conversations/${selectedUserId}/reply`, {
./src/pages/support-chat.tsx:            <Button size="icon" variant="ghost" onClick={() => refetchConvs()} className="h-7 w-7">
./src/pages/security.tsx:import { fetcher } from "@/lib/api";
./src/pages/security.tsx:      const data = await fetcher("/platform-settings");
./src/pages/security.tsx:  const fetchLiveData = useCallback(async () => {
./src/pages/security.tsx:        fetch(`${window.location.origin}/api/admin/security-dashboard`, { headers: apiHeaders }).then(checkOk),
./src/pages/security.tsx:        fetch(`${window.location.origin}/api/admin/login-lockouts`,     { headers: apiHeaders }).then(checkOk),
./src/pages/security.tsx:        fetch(`${window.location.origin}/api/admin/blocked-ips`,        { headers: apiHeaders }).then(checkOk),
./src/pages/security.tsx:        fetch(`${window.location.origin}/api/admin/security-events?limit=30`, { headers: apiHeaders }).then(checkOk),
./src/pages/security.tsx:  const fetchMfaStatus = useCallback(async () => {
./src/pages/security.tsx:      const data = await fetch(`${window.location.origin}/api/admin/mfa/status`, { headers: apiHeaders }).then(r => r.json());
./src/pages/security.tsx:    if (secTab === "auth" || secTab === "fraud") fetchLiveData();
./src/pages/security.tsx:    if (secTab === "auth") fetchMfaStatus();
./src/pages/security.tsx:  }, [secTab, fetchLiveData, fetchMfaStatus]);
./src/pages/security.tsx:      await fetcher("/platform-settings", { method: "PUT", body: JSON.stringify({ settings: changed }) });
./src/pages/security.tsx:      const r = await fetch(`${window.location.origin}/api/admin/login-lockouts/${encodeURIComponent(phone)}`, {
./src/pages/security.tsx:      fetchLiveData();
./src/pages/security.tsx:      const r = await fetch(`${window.location.origin}/api/admin/blocked-ips`, {
./src/pages/security.tsx:      fetchLiveData();
./src/pages/security.tsx:      const r = await fetch(`${window.location.origin}/api/admin/blocked-ips/${encodeURIComponent(ip)}`, {
./src/pages/security.tsx:      fetchLiveData();
./src/pages/security.tsx:      const data = await fetch(`${window.location.origin}/api/admin/mfa/setup`, {
./src/pages/security.tsx:      const data = await fetch(`${window.location.origin}/api/admin/mfa/verify`, {
./src/pages/security.tsx:        setMfaSetupData(null); setMfaToken(""); fetchMfaStatus();
./src/pages/security.tsx:      const data = await fetch(`${window.location.origin}/api/admin/mfa/disable`, {
./src/pages/security.tsx:        setDisableToken(""); fetchMfaStatus();
./src/pages/security.tsx:              <Button size="sm" variant="outline" className="h-7 text-xs gap-1" onClick={fetchLiveData} disabled={liveLoading}>
./src/pages/security.tsx:              <Button size="sm" variant="outline" className="h-7 text-xs gap-1" onClick={fetchLiveData} disabled={liveLoading}>
./src/pages/rides.tsx:  const { data, isLoading, isError, error, refetch } = useRideDetail(rideId);
./src/pages/rides.tsx:          <button onClick={() => refetch()} className="px-4 py-2 bg-primary text-white text-sm font-bold rounded-xl hover:opacity-90">Retry</button>
./src/pages/rides.tsx:      onSuccess: (d: any) => { toast({ title: `Refunded ${formatCurrency(Number(d.refundedAmount))}` }); setShowRefund(false); refetch(); },
./src/pages/rides.tsx:      onSuccess: () => { toast({ title: "Rider reassigned" }); setShowReassign(false); refetch(); },
./src/pages/rides.tsx:/* ── Tile config hook: fetches provider from /api/maps/config?app=admin ── */
./src/pages/rides.tsx:    fetch(`${window.location.origin}/api/maps/config?app=admin`)
./src/pages/DepositRequests.tsx:  const { data, isLoading, refetch } = useDepositRequests();
./src/pages/DepositRequests.tsx:        <Button variant="outline" size="sm" onClick={() => refetch()} className="self-start sm:self-auto">
./src/pages/delivery-access.tsx:  const { data, isLoading, refetch, isFetching } = useDeliveryAccess();
./src/pages/delivery-access.tsx:        <Button variant="outline" size="sm" onClick={() => refetch()} disabled={isFetching} className="h-9 rounded-xl gap-2">
./src/pages/kyc.tsx:      const r = await fetch(`${API_BASE}/kyc/admin/${record.id}/approve`, { method: "POST", headers: adminHeaders() });
./src/pages/kyc.tsx:      const r = await fetch(`${API_BASE}/kyc/admin/${record.id}/reject`, { method: "POST", headers: adminHeaders(), body: JSON.stringify({ reason }) });
./src/pages/kyc.tsx:      const r = await fetch(`${API_BASE}/kyc/admin/${record.id}`, { headers: adminHeaders() });
./src/pages/kyc.tsx:      if (!r.ok) throw new Error("Failed to fetch details");
./src/pages/kyc.tsx:  const { data, isLoading, refetch } = useQuery({
./src/pages/kyc.tsx:      const r = await fetch(`${API_BASE}/kyc/admin/list?status=${statusFilter}&limit=50`, { headers: adminHeaders() });
./src/pages/kyc.tsx:      if (!r.ok) throw new Error("Failed to fetch KYC list");
./src/pages/kyc.tsx:    refetchInterval: 30000,
./src/pages/kyc.tsx:        <button onClick={() => refetch()} className="flex items-center gap-2 text-sm text-gray-500 hover:text-gray-700 border border-gray-200 px-3 py-2 rounded-xl hover:bg-gray-50 transition">
./src/pages/webhook-manager.tsx:import { fetcher } from "@/lib/api";
./src/pages/webhook-manager.tsx:  const { data, isLoading, refetch } = useQuery({
./src/pages/webhook-manager.tsx:    queryFn: () => fetcher("/webhooks"),
./src/pages/webhook-manager.tsx:    refetchInterval: 30_000,
./src/pages/webhook-manager.tsx:    queryFn: () => fetcher(`/webhooks/${showLogs}/logs`),
./src/pages/webhook-manager.tsx:    mutationFn: (body: any) => fetcher("/webhooks", { method: "POST", body: JSON.stringify(body) }),
./src/pages/webhook-manager.tsx:    mutationFn: (id: string) => fetcher(`/webhooks/${id}/toggle`, { method: "PATCH", body: "{}" }),
./src/pages/webhook-manager.tsx:    mutationFn: (id: string) => fetcher(`/webhooks/${id}/test`, { method: "POST", body: "{}" }),
./src/pages/webhook-manager.tsx:    mutationFn: (id: string) => fetcher(`/webhooks/${id}`, { method: "DELETE" }),
./src/pages/webhook-manager.tsx:    <PullToRefresh onRefresh={async () => { await refetch(); }}>
./src/pages/chat-monitor.tsx:import { fetcher } from "@/lib/api";
./src/pages/chat-monitor.tsx:    queryFn: () => fetcher("/chat-monitor/conversations?limit=200"),
./src/pages/chat-monitor.tsx:    refetchInterval: 30_000,
./src/pages/chat-monitor.tsx:    queryFn: () => fetcher(`/chat-monitor/conversations/${id}/messages?limit=200`),
./src/pages/chat-monitor.tsx:    queryFn: () => fetcher(`/chat-monitor/reports${params}`),
./src/pages/chat-monitor.tsx:    refetchInterval: 30_000,
./src/pages/chat-monitor.tsx:    mutationFn: (userId: string) => fetcher(`/chat-monitor/users/${userId}/chat-mute`, { method: "POST", body: "{}" }),
./src/pages/chat-monitor.tsx:    mutationFn: (userId: string) => fetcher(`/chat-monitor/users/${userId}/chat-unmute`, { method: "POST", body: "{}" }),
./src/pages/chat-monitor.tsx:    mutationFn: (id: string) => fetcher(`/chat-monitor/reports/${id}/resolve`, { method: "PATCH", body: "{}" }),
./src/pages/transactions.tsx:  const { data, isLoading, refetch, isFetching } = useTransactions();
./src/pages/transactions.tsx:          <Button variant="outline" size="sm" onClick={() => refetch()} disabled={isFetching} className="h-9 rounded-xl gap-2 self-start sm:self-auto">
./src/pages/banners.tsx:import { fetcher } from "@/lib/api";
./src/pages/banners.tsx:      const uploadRes = await fetch(`${window.location.origin}/api/uploads`, {
./src/pages/banners.tsx:    queryFn: () => fetcher("/banners"),
./src/pages/banners.tsx:    refetchInterval: 30000,
./src/pages/banners.tsx:      if (editing) return fetcher(`/banners/${editing.id}`, { method: "PATCH", body: JSON.stringify(body) });
./src/pages/banners.tsx:      return fetcher("/banners", { method: "POST", body: JSON.stringify(body) });
./src/pages/banners.tsx:    mutationFn: (id: string) => fetcher(`/banners/${id}`, { method: "DELETE" }),
./src/pages/banners.tsx:      fetcher(`/banners/${id}`, { method: "PATCH", body: JSON.stringify({ isActive }) }),
./src/pages/banners.tsx:      fetcher("/banners/reorder", { method: "PATCH", body: JSON.stringify({ items }) }),
./src/pages/wallet-transfers.tsx:import { fetcher, apiFetch } from "@/lib/api";
./src/pages/wallet-transfers.tsx:    queryFn: () => fetcher("/wallet/stats"),
./src/pages/wallet-transfers.tsx:  const { data, isLoading, refetch } = useQuery({
./src/pages/wallet-transfers.tsx:    queryFn: () => fetcher(`/wallet/p2p-transactions?${params}`),
./src/pages/wallet-transfers.tsx:        <Button variant="outline" size="sm" onClick={() => refetch()}>
./src/pages/wallet-transfers.tsx:  const { data, isLoading, refetch } = useQuery({
./src/pages/wallet-transfers.tsx:    queryFn: () => fetcher("/settings"),
./src/pages/wallet-transfers.tsx:        <Button variant="outline" onClick={() => { setFields({}); refetch(); }}>Reset</Button>
./src/pages/settings-payment.tsx:import { fetcher } from "@/lib/api";
./src/pages/settings-payment.tsx:      const r = await fetch(`/api/payments/test-connection/${prefix}`, {
./src/pages/live-riders-map.tsx:import { fetcher } from "@/lib/api";
./src/pages/live-riders-map.tsx:  const { data, isLoading, refetch } = useQuery({
./src/pages/live-riders-map.tsx:    queryFn: () => fetcher(`/fleet-analytics?from=${fromDate}&to=${toDate}`),
./src/pages/live-riders-map.tsx:        <Button variant="outline" size="sm" onClick={() => refetch()} disabled={isLoading} className="h-9 rounded-xl gap-2">
./src/pages/live-riders-map.tsx:  const { data, isLoading, refetch, dataUpdatedAt } = useLiveRiders();
./src/pages/live-riders-map.tsx:        const res = await fetch(`${window.location.origin}/api/maps/config?app=admin`);
./src/pages/live-riders-map.tsx:    refetchOnWindowFocus: false,
./src/pages/live-riders-map.tsx:          <Button variant="outline" size="sm" onClick={() => refetch()} disabled={isLoading} className="h-8 rounded-xl gap-1.5">
./src/pages/van.tsx:  const res = await fetch(`${apiBase()}${path}`, {
./src/pages/van.tsx:  const { data: bookings = [], isLoading, refetch } = useQuery<VanBooking[]>({
./src/pages/van.tsx:        <Button variant="outline" size="sm" onClick={() => refetch()}><RefreshCw className="w-4 h-4" /></Button>
./src/pages/van.tsx:  const res = await fetch(`${adminApiBase()}${path}`, {
./src/pages/van.tsx:  const { data: settingsData, isLoading, refetch } = useQuery<{ settings: PlatformSetting[] }>({
./src/pages/van.tsx:          <Button size="sm" variant="outline" onClick={() => refetch()}><RefreshCw className="w-4 h-4 mr-1" />Refresh</Button>
./src/pages/app-management.tsx:import { fetcher } from "@/lib/api";
./src/pages/app-management.tsx:  const { data, isLoading, refetch, isFetching } = useAuditLog({ page, action: action || undefined, from: dateFrom || undefined, to: dateTo || undefined });
./src/pages/app-management.tsx:          <Button variant="outline" size="sm" onClick={() => refetch()} disabled={isFetching} className="h-9 rounded-xl gap-2">
./src/pages/app-management.tsx:  const { data: overview, isLoading: overviewLoading, refetch: refetchOverview } = useQuery<AppOverview>({
./src/pages/app-management.tsx:    queryFn: () => fetcher("/app-overview"),
./src/pages/app-management.tsx:    refetchInterval: 30000,
./src/pages/app-management.tsx:  const { data: adminsData, isLoading: adminsLoading, refetch: refetchAdmins } = useQuery({
./src/pages/app-management.tsx:    queryFn: () => fetcher("/admin-accounts"),
./src/pages/app-management.tsx:    queryFn: () => fetcher("/platform-settings"),
./src/pages/app-management.tsx:  const { data: rnData, isLoading: rnLoading, refetch: refetchRn } = useQuery({
./src/pages/app-management.tsx:    queryFn: () => fetcher("/admin/release-notes"),
./src/pages/app-management.tsx:      if (editingRn) return fetcher(`/admin/release-notes/${editingRn.id}`, { method: "PATCH", body: JSON.stringify(body) });
./src/pages/app-management.tsx:      return fetcher("/admin/release-notes", { method: "POST", body: JSON.stringify(body) });
./src/pages/app-management.tsx:    mutationFn: (id: string) => fetcher(`/admin/release-notes/${id}`, { method: "DELETE" }),
./src/pages/app-management.tsx:      await fetcher("/platform-settings", { method: "PUT", body: JSON.stringify({ settings: pairs }) });
./src/pages/app-management.tsx:      if (editingAdmin) return fetcher(`/admin-accounts/${editingAdmin.id}`, { method: "PATCH", body: JSON.stringify(body) });
./src/pages/app-management.tsx:      return fetcher("/admin-accounts", { method: "POST", body: JSON.stringify(body) });
./src/pages/app-management.tsx:    mutationFn: (id: string) => fetcher(`/admin-accounts/${id}`, { method: "DELETE" }),
./src/pages/app-management.tsx:      fetcher(`/admin-accounts/${id}`, { method: "PATCH", body: JSON.stringify({ isActive }) }),
./src/pages/app-management.tsx:      fetcher("/platform-settings", { method: "PUT", body: JSON.stringify({ settings: [{ key, value }] }) }),
./src/pages/app-management.tsx:      await fetcher("/platform-settings", { method: "PUT", body: JSON.stringify({ settings: [{ key: "app_status", value: newStatus }] }) });
./src/pages/app-management.tsx:          <Button variant="outline" onClick={() => { refetchOverview(); refetchAdmins(); }} className="h-10 rounded-xl gap-2">
./src/pages/launch-control.tsx:import { fetcher } from "@/lib/api";
./src/pages/launch-control.tsx:  /* ── Data fetching ── */
./src/pages/launch-control.tsx:  const { data: launchData, isLoading, refetch } = useQuery<LaunchData>({
./src/pages/launch-control.tsx:    queryFn: () => fetcher("/launch/settings") as Promise<LaunchData>,
./src/pages/launch-control.tsx:    queryFn: () => fetcher("/launch/vendor-plans") as Promise<PlansData>,
./src/pages/launch-control.tsx:    queryFn: () => fetcher("/launch/role-presets") as Promise<PresetsData>,
./src/pages/launch-control.tsx:    const resp = await fetch(url, { ...options, headers });
./src/pages/launch-control.tsx:        <Button variant="outline" onClick={() => refetch()} className="h-10 rounded-xl gap-2">
./src/pages/settings-integrations.tsx:import { fetcher } from "@/lib/api";
./src/pages/settings-integrations.tsx:      const data = await fetcher(`/system/test-integration/${type}`, {
./src/pages/categories.tsx:import { fetcher } from "@/lib/api";
./src/pages/categories.tsx:    queryFn: () => fetcher(`/categories/tree${filterType ? `?type=${filterType}` : ""}`),
./src/pages/categories.tsx:    refetchInterval: 30000,
./src/pages/categories.tsx:      if (editing) return fetcher(`/categories/${editing.id}`, { method: "PATCH", body: JSON.stringify(body) });
./src/pages/categories.tsx:      return fetcher("/categories", { method: "POST", body: JSON.stringify(body) });
./src/pages/categories.tsx:    mutationFn: (id: string) => fetcher(`/categories/${id}`, { method: "DELETE" }),
./src/pages/categories.tsx:      fetcher(`/categories/${id}`, { method: "PATCH", body: JSON.stringify({ isActive }) }),
./src/pages/categories.tsx:      fetcher("/categories/reorder", { method: "POST", body: JSON.stringify({ items }) }),
./src/pages/settings-security.tsx:  const fetchLiveData = useCallback(async () => {
./src/pages/settings-security.tsx:        fetch(`${window.location.origin}/api/admin/security-dashboard`, { headers: apiHeaders }).then(r => r.json()),
./src/pages/settings-security.tsx:        fetch(`${window.location.origin}/api/admin/login-lockouts`,     { headers: apiHeaders }).then(r => r.json()),
./src/pages/settings-security.tsx:        fetch(`${window.location.origin}/api/admin/blocked-ips`,        { headers: apiHeaders }).then(r => r.json()),
./src/pages/settings-security.tsx:        fetch(`${window.location.origin}/api/admin/audit-log?limit=50`, { headers: apiHeaders }).then(r => r.json()),
./src/pages/settings-security.tsx:        fetch(`${window.location.origin}/api/admin/security-events?limit=50`, { headers: apiHeaders }).then(r => r.json()),
./src/pages/settings-security.tsx:      fetchLiveData();
./src/pages/settings-security.tsx:  }, [secTab, fetchLiveData]);
./src/pages/settings-security.tsx:    await fetch(`${window.location.origin}/api/admin/login-lockouts/${encodeURIComponent(phone)}`, {
./src/pages/settings-security.tsx:    fetchLiveData();
./src/pages/settings-security.tsx:    await fetch(`${window.location.origin}/api/admin/blocked-ips`, {
./src/pages/settings-security.tsx:    fetchLiveData();
./src/pages/settings-security.tsx:    await fetch(`${window.location.origin}/api/admin/blocked-ips/${encodeURIComponent(ip)}`, {
./src/pages/settings-security.tsx:    fetchLiveData();
./src/pages/settings-security.tsx:  const fetchMfaStatus = useCallback(async () => {
./src/pages/settings-security.tsx:      const data = await fetch(`${window.location.origin}/api/admin/mfa/status`, { headers: apiHeaders }).then(r => r.json());
./src/pages/settings-security.tsx:    if (secTab === "admin") fetchMfaStatus();
./src/pages/settings-security.tsx:  }, [secTab, fetchMfaStatus]);
./src/pages/settings-security.tsx:      const data = await fetch(`${window.location.origin}/api/admin/mfa/setup`, { method: "POST", headers: apiHeaders }).then(r => r.json());
./src/pages/settings-security.tsx:      const data = await fetch(`${window.location.origin}/api/admin/mfa/verify`, {
./src/pages/settings-security.tsx:        setMfaSetupData(null); setMfaToken(""); fetchMfaStatus();
./src/pages/settings-security.tsx:      const data = await fetch(`${window.location.origin}/api/admin/mfa/disable`, {
./src/pages/settings-security.tsx:        setDisableToken(""); fetchMfaStatus();
./src/pages/settings-security.tsx:              <Button size="sm" variant="outline" className="h-7 text-xs gap-1" onClick={fetchLiveData} disabled={liveLoading}>
./src/pages/settings-security.tsx:              <Button size="sm" variant="outline" className="h-7 text-xs gap-1" onClick={fetchLiveData} disabled={liveLoading}>
./src/pages/settings-security.tsx:                <Button size="sm" variant="outline" className="h-7 text-xs gap-1" onClick={fetchLiveData} disabled={liveLoading}>
./src/pages/settings-security.tsx:              <Button size="sm" variant="outline" className="h-7 text-xs gap-1" onClick={fetchLiveData} disabled={liveLoading}>
./src/App.tsx:      refetchOnWindowFocus: false,
./src/App.tsx:    fetch(`${base}/api/platform-config`)
./src/lib/error-reporter.ts:    await fetch(`${getApiBase()}/error-reports`, {
./src/lib/api.ts:        const res = await fetch(`${getApiBase()}/uploads/admin`, {
./src/lib/api.ts:export const fetcher = async (endpoint: string, options: RequestInit = {}) => {
./src/lib/api.ts:  const res = await fetch(`${getApiBase()}${endpoint}`, {
./src/lib/api.ts:export const fetcherWithMeta = async (endpoint: string, options: RequestInit = {}): Promise<{ data: unknown; total?: number; [key: string]: unknown }> => {
./src/lib/api.ts:  const res = await fetch(`${getApiBase()}${endpoint}`, {
./src/lib/api.ts:export const apiFetch = fetcher;
./src/lib/useLanguage.ts:import { fetcher, getToken } from "./api";
./src/lib/useLanguage.ts:        const data = await fetcher("/me/language");
./src/lib/useLanguage.ts:        const data = await fetcher("/platform-settings") as { settings?: { key: string; value: string }[] };
./src/lib/useLanguage.ts:      await fetcher("/me/language", { method: "PUT", body: JSON.stringify({ language: lang }) });
./src/lib/push.ts:    const vapidRes = await fetch(`${BASE}/api/push/vapid-key`);
./src/lib/push.ts:    await fetch(`${BASE}/api/push/subscribe`, {
./src/lib/platformConfig.ts:import { fetcher } from "./api";
./src/lib/platformConfig.ts:    const data = await fetcher("/platform-settings");
./src/components/layout/AdminLayout.tsx:import { fetcher, isTokenExpired, clearToken, getToken } from "@/lib/api";
./src/components/layout/AdminLayout.tsx:    fetcher("/sos/alerts?limit=1")
./src/components/layout/AdminLayout.tsx:    fetcher("/error-reports/new-count")
./src/components/layout/AdminLayout.tsx:      fetcher("/error-reports/new-count")
./src/components/CommandPalette.tsx:import { fetcher, getToken } from "@/lib/api";
./src/components/CommandPalette.tsx:      const r = await fetch(`${window.location.origin}/api/admin/command/execute`, {
./src/components/CommandPalette.tsx:    queryFn:  () => fetcher(`/admin/search?${backendParams.toString()}`),
./src/components/CommandPalette.tsx:      const res = await fetch(`${window.location.origin}/api/admin/search/ai`, {
./src/components/UniversalMap.tsx: * (~700 KB) is only fetched when the admin has actually configured a
./src/components/UniversalMap.tsx: * Map provider and API token are fetched from /api/maps/config (DB-managed)
./src/components/UniversalMap.tsx:  /** Mapbox access token / Google Maps API key (fetched from backend) */
./src/components/UniversalMap.tsx:   Uses @googlemaps/js-api-loader so the API script is fetched lazily only
./src/components/MapsMgmtSection.tsx:  const res = await fetch(`${API_BASE()}${path}`, {
./src/components/MapsMgmtSection.tsx:      const data = await fetch(`${API_BASE()}/maps/config`).then(r => r.json());

### BACKEND CONTROLLERS & DB MODELS
