/********************************************************************\
 * io-example-account.h -- api for example accounts                 *
 *                                                                  *
 * Copyright (C) 2001 James LewisMoss <dres@debian.org>             *
 *                                                                  *
 * This program is free software; you can redistribute it and/or    *
 * modify it under the terms of the GNU General Public License as   *
 * published by the Free Software Foundation; either version 2 of   *
 * the License, or (at your option) any later version.              *
 *                                                                  *
 * This program is distributed in the hope that it will be useful,  *
 * but WITHOUT ANY WARRANTY; without even the implied warranty of   *
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the    *
 * GNU General Public License for more details.                     *
 *                                                                  *
 * You should have received a copy of the GNU General Public License*
 * along with this program; if not, contact:                        *
 *                                                                  *
 * Free Software Foundation           Voice:  +1-617-542-5942       *
 * 59 Temple Place - Suite 330        Fax:    +1-617-542-2652       *
 * Boston, MA  02111-1307,  USA       gnu@gnu.org                   *
 *                                                                  *
\********************************************************************/

#ifndef __IO_EXAMPLE_ACCOUNT_H__
#define __IO_EXAMPLE_ACCOUNT_H__

#include <glib.h>

#include "sixtp.h"
#include "Group.h"

struct GncExampleAccount_struct
{
    gchar *title;
    gchar *filename;
    AccountGroup *group;
    gchar *short_description;
    gchar *long_description;
};
typedef struct GncExampleAccount_struct GncExampleAccount;

GncExampleAccount* gnc_create_example_account(
    AccountGroup *grp, const char *title, const char *filename,
    const char *short_descrip, const char *long_descrip);

void gnc_destroy_example_account(GncExampleAccount *gea);

gboolean gnc_write_example_account(GncExampleAccount *gea,
                                   const gchar *filename);
GncExampleAccount *gnc_read_example_account(const gchar *filename);


gboolean gnc_is_xml_data_file_v2(const gchar *filename);

void gnc_free_example_account_list(GSList *list);
GSList* gnc_load_example_account_list(const char *dirname);

gboolean gnc_is_example_account_xml(const gchar *name);

#endif /* __IO_EXAMPLE_ACCOUNT_H__ */
