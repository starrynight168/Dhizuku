package com.rosan.dhizuku.data.common.util

import android.os.Binder
import android.os.IBinder
import android.os.Parcel
import android.os.ParcelFileDescriptor
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.withContext
import java.io.ByteArrayOutputStream
import java.io.FileDescriptor
import java.io.InputStream

private const val MAX_DUMP_BYTES = 4 * 1024 * 1024

private fun IBinder.transactDump(fd: FileDescriptor, args: Array<String>?) {
    val data = Parcel.obtain()
    val reply = Parcel.obtain()
    try {
        data.writeFileDescriptor(fd)
        data.writeStringArray(args)
        check(transact(Binder.DUMP_TRANSACTION, data, reply, 0)) {
            "System service did not handle the diagnostic dump request"
        }
        reply.readException()
    } finally {
        data.recycle()
        reply.recycle()
    }
}

suspend fun IBinder.dumpText(args: Array<String>? = null): String =
    withContext(Dispatchers.IO) {
        val (readEnd, writeEnd) = ParcelFileDescriptor.createPipe()
        readEnd.use {
            val reader = async {
                ParcelFileDescriptor.AutoCloseInputStream(readEnd).use { it.readDumpText() }
            }
            writeEnd.use { transactDump(it.fileDescriptor, args) }
            reader.await()
        }
    }

private fun InputStream.readDumpText(): String {
    val output = ByteArrayOutputStream()
    val buffer = ByteArray(DEFAULT_BUFFER_SIZE)
    var truncated = false
    while (true) {
        val count = read(buffer)
        if (count < 0) break
        val kept = minOf(count, MAX_DUMP_BYTES - output.size())
        output.write(buffer, 0, kept)
        if (kept < count) truncated = true
    }
    check(!truncated) { "System diagnostic output exceeded $MAX_DUMP_BYTES bytes" }
    return output.toString(Charsets.UTF_8.name())
}
