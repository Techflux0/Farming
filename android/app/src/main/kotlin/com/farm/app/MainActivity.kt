package com.farm.app

import io.flutter.embedding.android.FlutterActivity
import android.os.Bundle
import java.io.File
import android.Manifest
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat

class MainActivity : FlutterActivity() {
    companion object {
        private const val STORAGE_PERMISSION_REQUEST_CODE = 1001
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        requestStoragePermissions()
    }

    private fun requestStoragePermissions() {
        val permissions = arrayOf(
            Manifest.permission.WRITE_EXTERNAL_STORAGE,
            Manifest.permission.READ_EXTERNAL_STORAGE
        )

        // Check if permissions are already granted
        val permissionsNeeded = permissions.filter {
            ContextCompat.checkSelfPermission(this, it) != PackageManager.PERMISSION_GRANTED
        }

        if (permissionsNeeded.isNotEmpty()) {
            // Request permissions
            ActivityCompat.requestPermissions(
                this,
                permissionsNeeded.toTypedArray(),
                STORAGE_PERMISSION_REQUEST_CODE
            )
        } else {
            // Permissions already granted, create directory
            createFarmingDirectory()
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        
        if (requestCode == STORAGE_PERMISSION_REQUEST_CODE) {
            // Check if all permissions were granted
            val allGranted = grantResults.all { it == PackageManager.PERMISSION_GRANTED }
            
            if (allGranted) {
                createFarmingDirectory()
            } else {
                println("Storage permissions denied")
            }
        }
    }

    private fun createFarmingDirectory() {
        try {
            // Get the external files directory (or internal if external isn't available)
            val baseDir = getExternalFilesDir(null) ?: filesDir
            
            // Create the Farming directory
            val farmingDir = File(baseDir, "Farming")
            if (!farmingDir.exists()) {
                if (farmingDir.mkdirs()) {
                    println("Farming directory created successfully")
                } else {
                    println("Failed to create Farming directory")
                }
            } else {
                println("Farming directory already exists")
            }
        } catch (e: Exception) {
            println("Error creating Farming directory: ${e.message}")
        }
    }
}