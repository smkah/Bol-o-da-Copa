'use client';

import React, { useEffect, useState } from 'react';
import Navbar from '@/components/Navbar';
import { motion } from 'motion/react';
import { Trophy, Medal, Star, AlertCircle, RefreshCw } from 'lucide-react';
import { supabase } from '@/lib/supabase';

export default function RankingPage() {
  const [ranking, setRanking] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchRanking = async () => {
      setLoading(true);
      try {
        const { data, error } = await supabase
          .from('profiles')
          .select('*')
          .order('points', { ascending: false })
          .limit(100);
        
        if (error) throw error;
        setRanking(data || []);
      } catch (err) {
        console.error("Error fetching ranking:", err);
      } finally {
        setLoading(false);
      }
    };
    fetchRanking();
  }, []);

  return (
    <div className="min-h-screen bg-[#0F172A] text-slate-100">
      <Navbar />

      <main className="max-w-7xl mx-auto p-6 md:p-12">
        <header className="mb-14">
          <p className="text-xs font-bold uppercase tracking-[0.3em] text-emerald-400 mb-2">Quadro de Honra</p>
          <h1 className="text-5xl md:text-6xl font-black uppercase tracking-tighter flex items-center gap-4">
            RANKING <span className="gradient-text italic">GLOBAL</span>
          </h1>
        </header>

        {loading ? (
          <div className="flex flex-col items-center justify-center py-32">
            <RefreshCw size={48} className="animate-spin text-emerald-500 mb-4" />
            <p className="text-xs font-black uppercase tracking-widest text-slate-500">Calculando Posições...</p>
          </div>
        ) : ranking.length > 0 ? (
          <div className="grid gap-4">
             {/* Podium for top 3 */}
             <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-12 items-end">
                {ranking.slice(0, 3).map((user, idx) => {
                  const positions = [
                    { label: '2º', height: 'h-48', color: 'bg-slate-400/10 text-slate-400 border-slate-400/30', order: 'order-2 md:order-1' },
                    { label: '1º', height: 'h-64', color: 'bg-amber-400/10 text-amber-500 border-amber-400/30', order: 'order-1 md:order-2 shadow-2xl shadow-amber-400/5 scale-110 md:scale-115' },
                    { label: '3º', height: 'h-40', color: 'bg-orange-800/10 text-orange-800 border-orange-800/30', order: 'order-3' }
                  ];
                  const pos = idx === 0 ? positions[1] : idx === 1 ? positions[0] : positions[2];
                  
                  return (
                    <motion.div 
                      key={user.id}
                      initial={{ opacity: 0, y: 20 }}
                      animate={{ opacity: 1, y: 0 }}
                      transition={{ delay: idx * 0.2 }}
                      className={`${pos.order} relative flex flex-col items-center`}
                    >
                      <div className="mb-6 relative">
                        <div className={`w-24 h-24 rounded-full border-4 ${pos.color.split(' ')[2]} flex items-center justify-center font-black text-4xl overflow-hidden shadow-2xl`}>
                          {user.full_name?.charAt(0) || user.email?.charAt(0) || '?'}
                        </div>
                        <div className={`absolute -top-4 -right-4 w-12 h-12 ${pos.color} flex items-center justify-center rounded-2xl font-black border-2 border-[#0F172A]`}>
                           {pos.label}
                        </div>
                      </div>
                      <div className={`w-full ${pos.height} ${pos.color} border-2 border-b-0 rounded-t-[40px] p-6 flex flex-col items-center justify-center text-center gap-2`}>
                        <h3 className="font-black uppercase tracking-tight text-lg line-clamp-1 truncate max-w-full">{user.full_name || user.email?.split('@')[0]}</h3>
                        <p className="font-black text-3xl">{user.points || 0}</p>
                        <p className="text-[10px] uppercase font-bold tracking-widest opacity-60">PONTOS ACUMULADOS</p>
                      </div>
                    </motion.div>
                  )
                })}
             </div>

             {/* The rest of the list */}
             <div className="space-y-3 mt-12">
               {ranking.slice(3).map((user, idx) => (
                 <motion.div 
                   key={user.id}
                   initial={{ opacity: 0, x: -20 }}
                   animate={{ opacity: 1, x: 0 }}
                   className="glass p-6 rounded-2xl flex items-center justify-between group hover:border-emerald-500/30 transition-all"
                 >
                   <div className="flex items-center gap-6">
                     <span className="w-8 font-black text-slate-700 italic text-xl">#{(idx + 4)}</span>
                     <div className="w-12 h-12 bg-slate-900 border border-slate-800 rounded-full flex items-center justify-center font-black text-slate-400 group-hover:text-emerald-400 transition-colors uppercase">
                       {user.full_name?.charAt(0) || user.email?.charAt(0) || '?'}
                     </div>
                     <div>
                       <p className="font-bold text-white group-hover:text-emerald-400 transition-colors">{user.full_name || user.email?.split('@')[0]}</p>
                       <p className="text-[10px] font-bold text-slate-500 uppercase tracking-widest">{user.email?.replace(/(.{3}).*(@.*)/, '$1***$2')}</p>
                     </div>
                   </div>
                   <div className="flex flex-col items-end">
                      <p className="text-2xl font-black text-white">{user.points || 0}</p>
                      <p className="text-[8px] font-black uppercase text-slate-700 tracking-widest">PONTOS</p>
                   </div>
                 </motion.div>
               ))}
             </div>
          </div>
        ) : (
          <div className="flex flex-col items-center justify-center py-32 glass rounded-[40px] border-dashed border-slate-700">
            <Trophy className="text-slate-800 mb-6" size={80} />
            <h2 className="text-2xl font-black uppercase tracking-tight mb-2">Ranking em breve</h2>
            <p className="text-slate-400 font-medium text-center max-w-md px-6">
              O quadro de pontuação global será ativado assim que as primeiras partidas da Copa 2026 forem concluídas.
            </p>
          </div>
        )}
      </main>
    </div>
  );
}
