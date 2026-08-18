import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/patient_case.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_shell.dart';
import '../widgets/form_fields.dart';
import '../widgets/page_header.dart';
import '../widgets/section_card.dart';
import 'result_screen.dart';

class CaseEntryScreen extends StatefulWidget {
  const CaseEntryScreen({super.key});

  @override
  State<CaseEntryScreen> createState() => _CaseEntryScreenState();
}

class _CaseEntryScreenState extends State<CaseEntryScreen> {
  late PatientCase _form;

  @override
  void initState() {
    super.initState();
    _form = PatientCase.defaultCase;
  }

  void _set(PatientCase Function(PatientCase) update) {
    setState(() => _form = update(_form));
  }

  void _submit() {
    context.read<AppState>().setDraft(_form);
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ResultScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentTab: ShellTab.newCase,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageHeader(
                title: 'Case Entry',
                subtitle: 'Enter clinical indices to predict the periodontal healing outcome.',
              ),
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionLabel('Patient'),
                    LayoutBuilder(builder: (context, c) {
                      final wide = c.maxWidth > 560;
                      final fields = [
                        SliderField(
                          label: 'Age',
                          unit: 'yrs',
                          value: _form.age.toDouble(),
                          min: 18,
                          max: 90,
                          step: 1,
                          onChanged: (v) => _set((f) => f.copyWith(age: v.round())),
                        ),
                        SegmentedField<Sex>(
                          label: 'Sex',
                          value: _form.sex,
                          options: const [Sex.male, Sex.female],
                          labelOf: (s) => s.label,
                          onChanged: (v) => _set((f) => f.copyWith(sex: v)),
                        ),
                        SegmentedField<YesNo>(
                          label: 'Diabetes',
                          value: _form.diabetes,
                          options: const [YesNo.no, YesNo.yes],
                          labelOf: (s) => s.label,
                          onChanged: (v) => _set((f) => f.copyWith(diabetes: v)),
                        ),
                      ];
                      return wide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (var i = 0; i < fields.length; i++) ...[
                                  Expanded(child: fields[i]),
                                  if (i != fields.length - 1) const SizedBox(width: 20),
                                ],
                              ],
                            )
                          : Column(
                              children: [
                                for (var i = 0; i < fields.length; i++) ...[
                                  fields[i],
                                  if (i != fields.length - 1) const SizedBox(height: 18),
                                ],
                              ],
                            );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionLabel('Clinical Indices', icon: Icons.monitor_heart_outlined),
                    LayoutBuilder(builder: (context, c) {
                      final wide = c.maxWidth > 520;
                      final indices = [
                        SliderField(
                          label: 'Probing Depth',
                          unit: 'mm',
                          hint: 'PPD',
                          value: _form.probingDepth,
                          min: 1,
                          max: 12,
                          step: 0.1,
                          onChanged: (v) => _set((f) => f.copyWith(probingDepth: v)),
                        ),
                        SliderField(
                          label: 'Clinical Attachment Loss',
                          unit: 'mm',
                          hint: 'CAL',
                          value: _form.clinicalAttachmentLoss,
                          min: 0,
                          max: 10,
                          step: 0.1,
                          onChanged: (v) => _set((f) => f.copyWith(clinicalAttachmentLoss: v)),
                        ),
                        SliderField(
                          label: 'Gingival Index',
                          hint: 'GI (0–3)',
                          value: _form.gingivalIndex,
                          min: 0,
                          max: 3,
                          step: 0.01,
                          onChanged: (v) => _set((f) => f.copyWith(gingivalIndex: v)),
                        ),
                        SliderField(
                          label: 'Plaque Index',
                          hint: 'PI (0–3)',
                          value: _form.plaqueIndex,
                          min: 0,
                          max: 3,
                          step: 0.01,
                          onChanged: (v) => _set((f) => f.copyWith(plaqueIndex: v)),
                        ),
                      ];
                      if (!wide) {
                        return Column(
                          children: [
                            for (var i = 0; i < indices.length; i++) ...[
                              indices[i],
                              if (i != indices.length - 1) const SizedBox(height: 20),
                            ],
                          ],
                        );
                      }
                      return Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: indices[0]),
                              const SizedBox(width: 24),
                              Expanded(child: indices[1]),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: indices[2]),
                              const SizedBox(width: 24),
                              Expanded(child: indices[3]),
                            ],
                          ),
                        ],
                      );
                    }),
                    const SizedBox(height: 22),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: SegmentedField<YesNo>(
                        label: 'Bleeding on Probing',
                        value: _form.bleedingOnProbing,
                        options: const [YesNo.no, YesNo.yes],
                        labelOf: (s) => s.label,
                        onChanged: (v) => _set((f) => f.copyWith(bleedingOnProbing: v)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionLabel('Proposed Surgical Procedure'),
                    LayoutBuilder(builder: (context, c) {
                      final cols = c.maxWidth > 480 ? 4 : 2;
                      return GridView.count(
                        crossAxisCount: cols,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 2.4,
                        children: kProcedures.map((p) {
                          final active = _form.procedure == p;
                          return InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _set((f) => f.copyWith(procedure: p)),
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: active ? AppColors.brand50 : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: active ? AppColors.brand500 : AppColors.gray200),
                              ),
                              child: Text(
                                p.label,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: active ? AppColors.brand700 : AppColors.gray600,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.auto_awesome, size: 19),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Text('Predict Outcome', style: TextStyle(fontSize: 15)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
