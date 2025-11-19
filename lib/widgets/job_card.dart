import 'package:flutter/material.dart';
import '../models/job.dart';
import '../utils/date_formatter.dart';

class JobCard extends StatelessWidget {
  final Job job;
  final VoidCallback? onTap;

  const JobCard({
    super.key,
    required this.job,
    this.onTap,
  });

  String _stripHtmlTags(String htmlString) {
    // Remove <style>...</style> blocks
    String noStyle = htmlString.replaceAll(RegExp(r'<style[^>]*>[\s\S]*?<\/style>', multiLine: true, caseSensitive: false), '');
    // Remove inline style attributes
    String noInlineStyle = noStyle.replaceAll(RegExp(r'style=\"[^\"]*\"'), '');
    // Remove all HTML tags
    String noHtml = noInlineStyle.replaceAll(RegExp(r"<[^>]*>"), '');
    return noHtml.trim();
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillChip(String skill) {
    const primaryColor = Colors.deepPurple;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Text(
        skill,
        style: const TextStyle(
          color: Colors.deepPurple,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Colors.deepPurple;
    final bgGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white,
        Colors.grey.shade50,
      ],
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: InkWell(
      onTap: () async {
        if (onTap != null) onTap!();
      },
        borderRadius: BorderRadius.circular(16),
      child: Container(
          width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
            gradient: bgGradient,
          border: Border.all(
              color: Colors.grey[300]!,
            width: 1,
          ),
          ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
              // Header: Company Logo, Job Title, and Featured Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  // Company Logo
                    Container(
                    width: 52,
                    height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: primaryColor.withOpacity(0.2),
                        width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: job.imageUrl.isNotEmpty
                          ? ClipRRect(
                            borderRadius: BorderRadius.circular(11),
                              child: Image.network(
                                job.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                        primaryColor.withOpacity(0.7),
                                          primaryColor,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    borderRadius: BorderRadius.circular(11),
                                    ),
                                    child: const Icon(
                                      Icons.business,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  );
                                },
                              ),
                            )
                          : Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                  primaryColor.withOpacity(0.7),
                                    primaryColor,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              borderRadius: BorderRadius.circular(11),
                              ),
                              child: const Icon(
                                Icons.business,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                    ),
                    const SizedBox(width: 12),
                  // Job Title and Company
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.title.isNotEmpty ? job.title : 'Untitled Position',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                              fontSize: 16,
                            height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            job.company?['name'] ?? 
                            job.employer?['companyName'] ?? 
                            job.companyName,
                          style: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  // Featured Badge
                    if (job.isFeatured)
                      Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                          Icon(Icons.star, size: 12, color: Colors.amber.shade700),
                          const SizedBox(width: 3),
                            Text(
                              'Featured',
                              style: TextStyle(
                              fontSize: 10,
                                color: Colors.amber.shade900,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: 16),
                
              // Job Details: Type, Location, Salary
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildInfoChip(
                      Icons.work_outline,
                      job.jobType.isNotEmpty == true ? job.jobType : 'Not Specified',
                      primaryColor,
                    ),
                    _buildInfoChip(
                      Icons.location_on_outlined,
                      job.location.isNotEmpty == true ? job.location : 'Location Not Specified',
                    const Color(0xFF666666),
                    ),
                  if (job.salary.isNotEmpty == true)
                  _buildInfoChip(
                    Icons.attach_money,
                    job.salary,
                      const Color(0xFF2E7D32),
                  ),
                ],
              ),
                
              // Description
                if (job.description.isNotEmpty == true) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                      color: primaryColor.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _stripHtmlTags(job.description),
                    style: TextStyle(
                        color: Colors.grey[700],
                      fontSize: 13,
                      height: 1.4,
                      fontWeight: FontWeight.w400,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                
              // Skills
                if (job.skills.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                  spacing: 6,
                  runSpacing: 6,
                    children: job.skills
                        .take(3)
                        .map((skill) => _buildSkillChip(skill))
                        .toList(),
                  ),
                ],
                
              // Footer: Posted Time and Views
              const SizedBox(height: 16),
                Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: primaryColor.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: primaryColor,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                job.createdAt != null 
                                    ? 'Posted ${DateFormatter.format(job.createdAt)}'
                                    : 'Posted date not available',
                              style: TextStyle(
                                  color: primaryColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (job.views > 0)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.visibility_outlined,
                              size: 14,
                              color: primaryColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${job.views} views',
                            style: TextStyle(
                                color: primaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
          ),
        ),
      ),
    );
  }
} 