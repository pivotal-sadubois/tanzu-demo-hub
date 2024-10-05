import jenkins.model.Jenkins
import org.jenkinsci.plugins.scriptsecurity.scripts.ScriptApproval

// Get the instance of ScriptApproval
def scriptApproval = ScriptApproval.get()

// Approve all pending script approvals
scriptApproval.getPendingScripts().each { script ->
    println "Approving script: ${script.getArtifactId()}"
    scriptApproval.approveScript(script.getArtifactId())
    println "Approving script: ${script.getVersion()}"
    scriptApproval.approveScript(script.getVersion())
}

// method org.apache.maven.model.Model getArtifactId
// method org.apache.maven.model.Model getVersion
