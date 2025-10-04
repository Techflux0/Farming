package com.farm.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.Manifest
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.content.Intent
import android.net.Uri
import android.provider.Settings
import android.widget.Toast
import androidx.core.content.FileProvider
import java.io.File

class MainActivity : FlutterActivity() {
    companion object {
        private const val STORAGE_PERMISSION_REQUEST_CODE = 1001
        private const val MANAGE_STORAGE_REQUEST_CODE = 1002
    }

    private val CHANNEL = "app.installer"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "installApk" -> {
                    val path = call.argument<String>("path")
                    if (path != null) {
                        installApk(File(path))
                        result.success(true)
                    } else {
                        result.error("NO_PATH", "APK path not found", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun installApk(file: File) {
        try {
            val intent = Intent(Intent.ACTION_VIEW)
            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_GRANT_READ_URI_PERMISSION
            
            val uri: Uri = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                FileProvider.getUriForFile(this, "$packageName.fileprovider", file)
            } else {
                Uri.fromFile(file)
            }
            
            intent.setDataAndType(uri, "application/vnd.android.package-archive")
            startActivity(intent)
        } catch (e: Exception) {
            Toast.makeText(this, "Error installing APK: ${e.message}", Toast.LENGTH_LONG).show()
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        checkAndRequestPermissions()
    }

    private fun checkAndRequestPermissions() {
        if (!hasRequiredPermissions()) {
            requestPermissions()
        } else {
            createFarmingDirectory()
        }
    }

    private fun hasRequiredPermissions(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            Environment.isExternalStorageManager()
        } else {
            ContextCompat.checkSelfPermission(this, Manifest.permission.READ_EXTERNAL_STORAGE) == PackageManager.PERMISSION_GRANTED &&
                    ContextCompat.checkSelfPermission(this, Manifest.permission.WRITE_EXTERNAL_STORAGE) == PackageManager.PERMISSION_GRANTED
        }
    }

    private fun requestPermissions() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            try {
                val intent = Intent(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION)
                intent.data = Uri.parse("package:$packageName")
                startActivityForResult(intent, MANAGE_STORAGE_REQUEST_CODE)
            } catch (e: Exception) {
                val intent = Intent(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION)
                startActivityForResult(intent, MANAGE_STORAGE_REQUEST_CODE)
            }
        } else {
            ActivityCompat.requestPermissions(
                this,
                arrayOf(
                    Manifest.permission.READ_EXTERNAL_STORAGE,
                    Manifest.permission.WRITE_EXTERNAL_STORAGE
                ),
                STORAGE_PERMISSION_REQUEST_CODE
            )
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        when (requestCode) {
            MANAGE_STORAGE_REQUEST_CODE -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R && Environment.isExternalStorageManager()) {
                    createFarmingDirectory()
                } else {
                    Toast.makeText(this, "Full storage access is required for the app to function properly", Toast.LENGTH_LONG).show()
                }
            }
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        
        when (requestCode) {
            STORAGE_PERMISSION_REQUEST_CODE -> {
                val allGranted = grantResults.all { it == PackageManager.PERMISSION_GRANTED }
                
                if (allGranted) {
                    createFarmingDirectory()
                } else {
                    Toast.makeText(this, "Storage permissions are required for the app to function properly", Toast.LENGTH_LONG).show()
                }
            }
        }
    }

    private fun createFarmingDirectory() {
        try {
            val baseDir = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                // Use app-specific directory on Android 11+
                getExternalFilesDir(null) ?: filesDir
            } else {
                // Try external storage first, fallback to internal
                Environment.getExternalStorageDirectory().takeIf { it.canWrite() } ?: getExternalFilesDir(null) ?: filesDir
            }
            
            val farmingDir = File(baseDir, "Farming")
            
            if (!farmingDir.exists()) {
                if (farmingDir.mkdirs()) {
                    println("Farming directory created successfully at: ${farmingDir.absolutePath}")
                } else {
                    println("Failed to create Farming directory")
                }
            } else {
                println("Farming directory already exists at: ${farmingDir.absolutePath}")
            }
        } catch (e: Exception) {
            println("Error creating Farming directory: ${e.message}")
            e.printStackTrace()
        }
    }
}