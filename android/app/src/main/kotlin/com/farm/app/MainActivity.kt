package com.farm.app

import io.flutter.embedding.android.FlutterActivity
import android.os.Bundle
import java.io.File

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createFarmingDirectory()
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