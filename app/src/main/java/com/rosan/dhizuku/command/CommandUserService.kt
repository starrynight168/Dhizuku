package com.rosan.dhizuku.command

import android.os.Process
import androidx.annotation.Keep
import org.json.JSONObject
import java.io.InputStream
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

@Keep
class CommandUserService : ICommandUserService.Stub() {
    override fun execute(command: String): String {
        val process = ProcessBuilder("sh", "-c", command).start()
        val readers = Executors.newFixedThreadPool(2)
        try {
            process.outputStream.close()
            val stdout = readers.submit<String> { process.inputStream.readLimited() }
            val stderr = readers.submit<String> { process.errorStream.readLimited() }
            val completed = process.waitFor(60, TimeUnit.SECONDS)
            if (!completed) process.destroyForcibly()
            return JSONObject()
                .put("stdout", stdout.get(5, TimeUnit.SECONDS))
                .put(
                    "stderr",
                    if (completed) stderr.get(5, TimeUnit.SECONDS)
                    else "Command timed out after 60 seconds",
                )
                .put("exitCode", if (completed) process.exitValue() else 124)
                .toString()
        } finally {
            process.destroy()
            readers.shutdownNow()
        }
    }

    override fun destroy() {
        Process.killProcess(Process.myPid())
    }

    private fun InputStream.readLimited(limit: Int = 262_144): String = bufferedReader().use { reader ->
        val output = StringBuilder()
        val buffer = CharArray(4096)
        var truncated = false
        while (true) {
            val count = reader.read(buffer)
            if (count < 0) break
            val remaining = limit - output.length
            if (remaining > 0) output.append(buffer, 0, minOf(count, remaining))
            if (count > remaining) truncated = true
        }
        if (truncated) output.append("\n[output truncated]")
        output.toString()
    }
}
