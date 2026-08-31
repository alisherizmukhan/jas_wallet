package com.jaswallet.app

import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaMuxer
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.nio.ByteBuffer

class VideoTrimPlugin {
    companion object {
        private const val CHANNEL = "com.jaswallet/video_trim"
        private val mainHandler = Handler(Looper.getMainLooper())

        fun registerWith(flutterEngine: FlutterEngine) {
            val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "trimVideo" -> {
                        val inputPath  = call.argument<String>("inputPath")
                        val outputPath = call.argument<String>("outputPath")
                        val startMs    = call.argument<Int>("startMs") ?: 0
                        val endMs      = call.argument<Int>("endMs")   ?: Int.MAX_VALUE

                        if (inputPath == null || outputPath == null) {
                            result.error("MISSING_ARG", "inputPath and outputPath are required", null)
                            return@setMethodCallHandler
                        }

                        Thread {
                            try {
                                trimVideo(inputPath, outputPath, startMs.toLong(), endMs.toLong())
                                mainHandler.post { result.success(outputPath) }
                            } catch (e: Exception) {
                                mainHandler.post {
                                    result.error("TRIM_FAILED", e.message ?: "Unknown error", null)
                                }
                            }
                        }.start()
                    }
                    else -> result.notImplemented()
                }
            }
        }

        private fun trimVideo(
            inputPath: String,
            outputPath: String,
            startMs: Long,
            endMs: Long,
        ) {
            val startUs = startMs * 1000L
            val endUs   = endMs * 1000L

            val extractor = MediaExtractor()
            try {
                extractor.setDataSource(inputPath)
                val trackCount = extractor.trackCount
                val muxer = MediaMuxer(outputPath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
                try {
                    // Map extractor track → muxer track
                    val trackMap = mutableMapOf<Int, Int>()
                    for (i in 0 until trackCount) {
                        val format   = extractor.getTrackFormat(i)
                        val muxerIdx = muxer.addTrack(format)
                        trackMap[i]  = muxerIdx
                        extractor.selectTrack(i)
                    }

                    muxer.start()

                    // Seek to the previous sync frame so we don't miss the start
                    extractor.seekTo(startUs, MediaExtractor.SEEK_TO_PREVIOUS_SYNC)

                    // Note the actual first sample time (may be before startUs)
                    val firstSampleUs = if (extractor.sampleTrackIndex >= 0) extractor.sampleTime else startUs

                    val buffer = ByteBuffer.allocate(2 * 1024 * 1024) // 2 MB read buffer
                    val info   = MediaCodec.BufferInfo()

                    while (true) {
                        val trackIdx = extractor.sampleTrackIndex
                        if (trackIdx < 0) break

                        val sampleUs = extractor.sampleTime
                        if (sampleUs > endUs) {
                            if (!extractor.advance()) break
                            continue
                        }

                        val size = extractor.readSampleData(buffer, 0)
                        if (size < 0) break

                        info.offset             = 0
                        info.size               = size
                        info.presentationTimeUs = (sampleUs - firstSampleUs).coerceAtLeast(0L)
                        info.flags              = extractor.sampleFlags

                        trackMap[trackIdx]?.let { muxerTrack ->
                            muxer.writeSampleData(muxerTrack, buffer, info)
                        }

                        if (!extractor.advance()) break
                    }

                    muxer.stop()
                } finally {
                    muxer.release()
                }
            } finally {
                extractor.release()
            }
        }
    }
}
