import { useState } from 'react';
import { X, Check } from 'lucide-react';
import { IconPicker } from './IconPicker';
import { ColorPicker } from './ColorPicker';
import { Habit } from '../App';

interface HabitFormProps {
  habit: Habit | null;
  onSave: (habit: Omit<Habit, 'id' | 'createdAt'>) => void;
  onCancel: () => void;
}

export function HabitForm({ habit, onSave, onCancel }: HabitFormProps) {
  const [title, setTitle] = useState(habit?.title || '');
  const [description, setDescription] = useState(habit?.description || '');
  const [iconId, setIconId] = useState(habit?.iconId || 'brain');
  const [color, setColor] = useState(habit?.color || '#8b5cf6');
  const [frequencyGoal, setFrequencyGoal] = useState(habit?.frequencyGoal || 1);
  const [frequencyPeriod, setFrequencyPeriod] = useState<'day' | 'week' | 'month'>(
    habit?.frequencyPeriod || 'day'
  );
  const [reminderTime, setReminderTime] = useState(habit?.reminders[0]?.time || '09:00');
  const [reminderDays, setReminderDays] = useState<string[]>(
    habit?.reminders[0]?.days || ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
  );

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!title.trim()) return;

    onSave({
      title: title.trim(),
      description: description.trim(),
      iconId,
      color,
      frequencyGoal,
      frequencyPeriod,
      history: habit?.history || {},
      reminders: reminderTime ? [{ time: reminderTime, days: reminderDays }] : []
    });
  };

  const toggleReminderDay = (day: string) => {
    setReminderDays(prev => 
      prev.includes(day) 
        ? prev.filter(d => d !== day)
        : [...prev, day]
    );
  };

  const weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  return (
    <div className="min-h-screen bg-[#0f1722] text-white">
      {/* Header */}
      <header className="sticky top-0 z-10 bg-[#0b1220]/95 backdrop-blur-sm border-b border-white/5">
        <div className="max-w-4xl mx-auto px-6 py-4 flex items-center justify-between">
          <button
            onClick={onCancel}
            className="p-2 hover:bg-white/5 rounded-xl transition-colors"
            aria-label="Cancel"
          >
            <X className="w-6 h-6" />
          </button>
          
          <h2 className="text-lg">{habit ? 'Edit Habit' : 'New Habit'}</h2>
          
          <button
            onClick={handleSubmit}
            disabled={!title.trim()}
            className="p-2 bg-[#2b2eee] hover:bg-[#2b2eee]/90 disabled:opacity-50 disabled:cursor-not-allowed rounded-xl transition-all hover:scale-105 active:scale-95"
            aria-label="Save"
          >
            <Check className="w-6 h-6" />
          </button>
        </div>
      </header>

      {/* Form */}
      <main className="max-w-4xl mx-auto px-6 py-8">
        <form onSubmit={handleSubmit} className="space-y-8">
          {/* Basic Info */}
          <div className="space-y-4">
            <div>
              <label htmlFor="title" className="block text-sm text-[#9aa3b2] mb-2">
                Habit Name
              </label>
              <input
                id="title"
                type="text"
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                placeholder="e.g., Morning Meditation"
                className="w-full px-4 py-3 bg-[#1a2332] border border-white/10 rounded-2xl focus:outline-none focus:border-white/20 transition-colors"
                autoFocus
              />
            </div>

            <div>
              <label htmlFor="description" className="block text-sm text-[#9aa3b2] mb-2">
                Description (optional)
              </label>
              <textarea
                id="description"
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                placeholder="Add more details about your habit..."
                rows={3}
                className="w-full px-4 py-3 bg-[#1a2332] border border-white/10 rounded-2xl focus:outline-none focus:border-white/20 transition-colors resize-none"
              />
            </div>
          </div>

          {/* Icon Picker */}
          <IconPicker selectedIcon={iconId} onSelect={setIconId} color={color} />

          {/* Color Picker */}
          <ColorPicker selectedColor={color} onSelect={setColor} />

          {/* Frequency */}
          <div className="space-y-3">
            <label className="block text-sm text-[#9aa3b2]">Frequency Goal</label>
            
            <div className="flex items-center gap-3">
              <input
                type="number"
                min="1"
                max="100"
                value={frequencyGoal}
                onChange={(e) => setFrequencyGoal(Math.max(1, parseInt(e.target.value) || 1))}
                className="w-20 px-4 py-3 bg-[#1a2332] border border-white/10 rounded-2xl focus:outline-none focus:border-white/20 transition-colors text-center"
              />
              
              <span className="text-[#9aa3b2]">times per</span>
              
              <select
                value={frequencyPeriod}
                onChange={(e) => setFrequencyPeriod(e.target.value as 'day' | 'week' | 'month')}
                className="flex-1 px-4 py-3 bg-[#1a2332] border border-white/10 rounded-2xl focus:outline-none focus:border-white/20 transition-colors cursor-pointer"
              >
                <option value="day">Day</option>
                <option value="week">Week</option>
                <option value="month">Month</option>
              </select>
            </div>

            <p className="text-xs text-[#9aa3b2]">
              Complete this habit {frequencyGoal} {frequencyGoal === 1 ? 'time' : 'times'} per {frequencyPeriod}
            </p>
          </div>

          {/* Reminders */}
          <div className="space-y-3">
            <label className="block text-sm text-[#9aa3b2]">Reminder (optional)</label>
            
            <input
              type="time"
              value={reminderTime}
              onChange={(e) => setReminderTime(e.target.value)}
              className="w-full px-4 py-3 bg-[#1a2332] border border-white/10 rounded-2xl focus:outline-none focus:border-white/20 transition-colors"
            />

            <div>
              <p className="text-xs text-[#9aa3b2] mb-2">Repeat on</p>
              <div className="flex gap-2">
                {weekDays.map(day => (
                  <button
                    key={day}
                    type="button"
                    onClick={() => toggleReminderDay(day)}
                    className={`flex-1 py-2 rounded-xl text-sm transition-all hover:scale-105 active:scale-95 ${
                      reminderDays.includes(day)
                        ? 'text-white'
                        : 'bg-white/5 text-[#9aa3b2]'
                    }`}
                    style={{
                      backgroundColor: reminderDays.includes(day) ? `${color}30` : undefined,
                      borderColor: reminderDays.includes(day) ? color : 'transparent',
                      borderWidth: reminderDays.includes(day) ? '1px' : '0'
                    }}
                  >
                    {day}
                  </button>
                ))}
              </div>
            </div>
          </div>

          {/* Preview Card */}
          <div className="pt-4 border-t border-white/5">
            <p className="text-sm text-[#9aa3b2] mb-3">Preview</p>
            <div className="bg-[#1a2332] rounded-3xl p-6 border border-white/5">
              <div className="flex items-start gap-4">
                <div 
                  className="flex-shrink-0 w-14 h-14 rounded-2xl flex items-center justify-center"
                  style={{ backgroundColor: `${color}20` }}
                >
                  <div className="w-7 h-7 rounded" style={{ backgroundColor: color }} />
                </div>
                <div className="flex-1">
                  <h3 className="mb-1">{title || 'Habit Name'}</h3>
                  <p className="text-[#9aa3b2] text-sm">{description || 'Description will appear here'}</p>
                  <div className="mt-3">
                    <span 
                      className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs"
                      style={{ 
                        backgroundColor: `${color}15`,
                        color: color
                      }}
                    >
                      {frequencyGoal}/{frequencyPeriod}
                    </span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </form>
      </main>
    </div>
  );
}
