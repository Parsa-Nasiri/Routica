import { ArrowLeft, Moon, Bell, Lock, Download, Trash2, Info } from 'lucide-react';
import { useState } from 'react';

interface SettingsPanelProps {
  onBack: () => void;
}

export function SettingsPanel({ onBack }: SettingsPanelProps) {
  const [notificationsEnabled, setNotificationsEnabled] = useState(true);
  const [highContrastMode, setHighContrastMode] = useState(false);

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center gap-4">
        <button
          onClick={onBack}
          className="p-2 hover:bg-white/5 rounded-xl transition-colors"
          aria-label="Back"
        >
          <ArrowLeft className="w-5 h-5" />
        </button>
        <h2>Settings</h2>
      </div>

      {/* Appearance */}
      <div className="space-y-3">
        <h3 className="text-sm text-[#9aa3b2]">Appearance</h3>
        
        <div className="bg-[#1a2332] rounded-2xl border border-white/5 divide-y divide-white/5">
          <button
            onClick={() => setHighContrastMode(!highContrastMode)}
            className="w-full flex items-center justify-between p-5 hover:bg-white/5 transition-colors"
          >
            <div className="flex items-center gap-3">
              <div className="p-2 bg-purple-500/20 rounded-xl">
                <Moon className="w-5 h-5 text-purple-400" />
              </div>
              <div className="text-left">
                <p>High Contrast Mode</p>
                <p className="text-xs text-[#9aa3b2] mt-0.5">Enhanced visibility</p>
              </div>
            </div>
            <div 
              className={`w-12 h-7 rounded-full transition-colors ${
                highContrastMode ? 'bg-purple-500' : 'bg-white/10'
              }`}
            >
              <div 
                className={`w-5 h-5 bg-white rounded-full m-1 transition-transform ${
                  highContrastMode ? 'translate-x-5' : 'translate-x-0'
                }`}
              />
            </div>
          </button>
        </div>
      </div>

      {/* Notifications */}
      <div className="space-y-3">
        <h3 className="text-sm text-[#9aa3b2]">Notifications</h3>
        
        <div className="bg-[#1a2332] rounded-2xl border border-white/5 divide-y divide-white/5">
          <button
            onClick={() => setNotificationsEnabled(!notificationsEnabled)}
            className="w-full flex items-center justify-between p-5 hover:bg-white/5 transition-colors"
          >
            <div className="flex items-center gap-3">
              <div className="p-2 bg-blue-500/20 rounded-xl">
                <Bell className="w-5 h-5 text-blue-400" />
              </div>
              <div className="text-left">
                <p>Habit Reminders</p>
                <p className="text-xs text-[#9aa3b2] mt-0.5">Get notified about your habits</p>
              </div>
            </div>
            <div 
              className={`w-12 h-7 rounded-full transition-colors ${
                notificationsEnabled ? 'bg-blue-500' : 'bg-white/10'
              }`}
            >
              <div 
                className={`w-5 h-5 bg-white rounded-full m-1 transition-transform ${
                  notificationsEnabled ? 'translate-x-5' : 'translate-x-0'
                }`}
              />
            </div>
          </button>
        </div>
      </div>

      {/* Data & Privacy */}
      <div className="space-y-3">
        <h3 className="text-sm text-[#9aa3b2]">Data & Privacy</h3>
        
        <div className="bg-[#1a2332] rounded-2xl border border-white/5 divide-y divide-white/5">
          <button className="w-full flex items-center justify-between p-5 hover:bg-white/5 transition-colors">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-green-500/20 rounded-xl">
                <Download className="w-5 h-5 text-green-400" />
              </div>
              <div className="text-left">
                <p>Export Data</p>
                <p className="text-xs text-[#9aa3b2] mt-0.5">Download your habits as JSON</p>
              </div>
            </div>
          </button>

          <button className="w-full flex items-center justify-between p-5 hover:bg-white/5 transition-colors">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-orange-500/20 rounded-xl">
                <Lock className="w-5 h-5 text-orange-400" />
              </div>
              <div className="text-left">
                <p>Privacy Settings</p>
                <p className="text-xs text-[#9aa3b2] mt-0.5">Manage your data preferences</p>
              </div>
            </div>
          </button>

          <button className="w-full flex items-center justify-between p-5 hover:bg-red-500/10 transition-colors group">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-red-500/20 rounded-xl">
                <Trash2 className="w-5 h-5 text-red-400" />
              </div>
              <div className="text-left">
                <p className="text-red-400">Clear All Data</p>
                <p className="text-xs text-[#9aa3b2] mt-0.5">Permanently delete all habits</p>
              </div>
            </div>
          </button>
        </div>
      </div>

      {/* About */}
      <div className="space-y-3">
        <h3 className="text-sm text-[#9aa3b2]">About</h3>
        
        <div className="bg-[#1a2332] rounded-2xl border border-white/5 divide-y divide-white/5">
          <button className="w-full flex items-center justify-between p-5 hover:bg-white/5 transition-colors">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-indigo-500/20 rounded-xl">
                <Info className="w-5 h-5 text-indigo-400" />
              </div>
              <div className="text-left">
                <p>Version</p>
                <p className="text-xs text-[#9aa3b2] mt-0.5">1.0.0</p>
              </div>
            </div>
          </button>
        </div>
      </div>

      {/* Info Note */}
      <div className="bg-blue-500/10 border border-blue-500/20 rounded-2xl p-5">
        <p className="text-sm text-blue-400">
          <span className="inline-block mr-2">ℹ️</span>
          Your habit data is stored locally on your device. Enable cloud backup in Data & Privacy to sync across devices.
        </p>
      </div>
    </div>
  );
}
