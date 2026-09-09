# Copyright (c) Matthias Wolf, Mawosoft.

Add-Type -TypeDefinition @'
// Note this needs to compile in 5.1 as well.
using System;
using System.Collections.Generic;
using System.Management.Automation;
using System.Reflection;
using System.Runtime.CompilerServices;
public static class TestLogger {
    public struct ObjWrapper : IEquatable<ObjWrapper> {
        private readonly object _object;
        public object Object { get { return _object; } }
        public ObjWrapper(object obj) {
            _object = obj;
        }
        public override bool Equals(object obj) {
            if (!(obj is ObjWrapper)) return false;
            return Equals((ObjWrapper)obj);
        }
        public bool Equals(ObjWrapper other) {
            return ReferenceEquals(_object, other._object);
        }
        public override int GetHashCode() {
            return RuntimeHelpers.GetHashCode(_object);
        }
        public override string ToString() {
            if (_object == null) return "<null>";
            var pi = _object.GetType().GetProperty("Module", BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);
            if (pi == null) return "<" + _object.GetType().Name + ">";
            var module = (PSModuleInfo)pi.GetValue(_object);
            if (module == null) return "<module-null>";
            var name = module.Name as string;
            if (name == null) return "<module-nullname>";
            return "module: " + name;
        }
    }
    public sealed class LogEntry {
        public string CalleeInfo { get; set; }
        public string CallerInfo { get; set; }
        public ObjWrapper CalleeSessionState { get; set; }
        public ObjWrapper CalleeSessionStateInternal { get; set; }
        public ObjWrapper PSCmdletSessionState { get; set; }
        public ObjWrapper PSCmdletSessionStateInternal { get; set; }
        public ObjWrapper FrameSessionStateInternal1 { get; set; }
        public ObjWrapper FrameSessionState { get; set; }
        public ObjWrapper FrameSessionStateInternal2 { get; set; }
        public Dictionary<ObjWrapper, string> Groups { get; set; }
    }

    private static List<LogEntry> s_log;
    public static List<LogEntry> Log { get { return s_log; } }

    static TestLogger() {
        s_log = new List<LogEntry>();
    }

    public static void LogCallee(string calleeInfo, string callerInfo, EngineIntrinsics executionContext, PSCmdlet psCmdlet, CallStackFrame callerFrame) {
        var bfi = BindingFlags.Instance | BindingFlags.NonPublic;
        var piInternal = typeof(SessionState).GetProperty("Internal", bfi);
        var piSs = typeof(ScriptBlock).GetProperty("SessionState", bfi);
        var piSsi = typeof(ScriptBlock).GetProperty("SessionStateInternal", bfi);
        var log = new LogEntry();
        log.CalleeInfo = calleeInfo;
        log.CallerInfo = callerInfo;
        log.CalleeSessionState = new ObjWrapper(executionContext.SessionState);
        log.CalleeSessionStateInternal = new ObjWrapper(piInternal.GetValue(executionContext.SessionState));
        log.PSCmdletSessionState = new ObjWrapper(psCmdlet.SessionState);
        log.PSCmdletSessionStateInternal = new ObjWrapper(piInternal.GetValue(psCmdlet.SessionState));
        var funcContext = typeof(CallStackFrame).GetProperty("FunctionContext", bfi).GetValue(callerFrame);
        var script = funcContext.GetType().GetField("_scriptBlock", bfi).GetValue(funcContext);
        log.FrameSessionStateInternal1 = new ObjWrapper(piSsi.GetValue(script));
        log.FrameSessionState = new ObjWrapper(piSs.GetValue(script));
        log.FrameSessionStateInternal2 = new ObjWrapper(piSsi.GetValue(script));
        var groups = new Dictionary<ObjWrapper, string>();
        foreach (var pi in typeof(LogEntry).GetProperties()) {
            if (pi.PropertyType != typeof(ObjWrapper)) continue;
            var w = (ObjWrapper)pi.GetValue(log);
            string list;
            if (groups.TryGetValue(w, out list)) {
                list += ", " + pi.Name;
                groups[w] = list;
            }
            else {
                groups[w] = pi.Name;
            }
        }
        log.Groups = groups;
        s_log.Add(log);
    }
}
'@
